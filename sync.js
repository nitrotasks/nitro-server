/* Nitro Sync
 *
 * Copyright (C) 2012 Caffeinated Code <http://caffeinatedco.de>
 * Copyright (C) 2012 Jono Cooper
 * Copyright (C) 2012 George Czabania
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * Neither the name of Caffeinated Code nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

settings = {
	version: "1.4.7",
	filename: 'nitro_data.json',
	todo: 'todo.txt',
	// url: 'http://app.nitrotasks.com',
	url: 'http://localhost:3000',
	debugMode: false
};

console.info('Nitro Sync '+settings.version+'\nCopyright (C) 2012 Caffeinated Code\nBy George Czabania & Jono Cooper');

// Node Packages
var express = require('express'),
	app = express.createServer(),
	dbox = require("dbox").app({ "app_key": "da4u54t1irdahco", "app_secret": "3ydqe041ogqe1zq" }),
	OAuth = require("oauth").OAuth,
	fs = require('fs')

require('./merge')
require('./upgrade')
require('./merge_1.4.3')
require('./upgrade_1.4.3')

// Ubuntu one settings
var ubuntu = new OAuth("https://one.ubuntu.com/oauth/request/", "https://one.ubuntu.com/oauth/access/", "ubuntuone", "hammertime", "1.0", settings.url + "/ubuntu-one/", "PLAINTEXT"),
	users = {dropbox: {}, ubuntu: {}};

//Funky Headers =)
app.use(function (req, res, next) {
	res.header("X-powered-by", "Heroku");
	next();
});

// Enable cross browser ajax
app.enable("jsonp callback");
app.use(express.bodyParser());

// Handles Static HTTP Requests
app.use(express.static(__dirname + '/app'));

// Initial Auth
app.post('/request_url', function (req, res) {
	requestURL(req, res);
})
app.post('/auth', function (req, res) {
	authenticate(req, res);
})

// Actual Sync
app.post('/sync/', function (req, res){
	sync(req, res);
})

// Dropbox callback
app.get('/dropbox', function (req, res) {

	// Get UID and token
	var uid = req.query.uid,
		token = req.query.oauth_token,
		url = settings.url+'/success/';

	// Update user token
	if(users.dropbox.hasOwnProperty(token)) {
		users.dropbox[token].uid = uid

		// If using web version, redirect back to web app
		if (users.dropbox[token].app == 'web') {
			url = settings.url;
		}
	}

	// Redirect user
	res.send('<meta HTTP-EQUIV="REFRESH" content="0; url='+url+'">');
});

// Ubuntu callback for oauth verifier
app.get('/ubuntu-one/', function (req, res) {

	// Get token
	var token = req.query.oauth_token,
		url = settings.url + '/success/';

	// Update user token
	if(users.ubuntu.hasOwnProperty(token)) {
		ubuntu.getOAuthAccessToken(token, users.ubuntu[token].request_secret, req.query.oauth_verifier, function(e, t, s, r) {
			users.ubuntu[token].oauth_token = t
			users.ubuntu[token].oauth_secret = s
		});

		// If using web version, redirect back to web app
		if (users.ubuntu[token].app == 'web') {
			url = settings.url;
		}
	}

	// Redirect user
	res.send('<meta HTTP-EQUIV="REFRESH" content="0; url='+url+'">');
});

port = process.env.PORT || 3000
app.listen(port)


// FUNCTIONS
isArray = function(obj) { return obj.constructor == Array }
isObject = function(obj) { return obj.constructor == Object }
isNumber = function(obj) { return !isNaN(parseFloat(obj)) && isFinite(obj) }
clone = function(obj) { return JSON.parse(JSON.stringify(obj)) }
ArrayDiff = function(a,b) { return a.filter(function(i) {return !(b.indexOf(i) > -1)})}

// Remap console.log() to msg()
msg = console.log

function requestURL(req, res) {

	switch (req.param('service')) {
		case "dropbox":
			// Request a token from dropbox
			dbox.requesttoken(function (status, request_token) {
				users.dropbox[request_token.oauth_token] = {
					token_secret: request_token.oauth_token_secret,
					app: req.param('app') == 'web' ? 'web' : 'js'
				}

				request_token.authorize_url += "&oauth_callback=" + settings.url + "/dropbox";
				res.json(request_token)
			})
			break
		case "ubuntu":
			// Request a token from ubuntu one
			ubuntu.getOAuthRequestToken(function(e, t, s, r){
				users.ubuntu[t] = {
					request_secret: s
				}
				res.json({
					oauth_token: t,
					oauth_secret: s,
					authorize_url: 'https://one.ubuntu.com/oauth/authorize/?description=Nitro&oauth_token=' + t
				})
			})
			break
		case "debug":
			// Use local file
			res.json({
				oauth_token: 'hello',
				oauth_secret: 'world',
				authorize_url: settings.url + '/success'
			})
	}
}

function authenticate(req, res) {
	
	// Get token and make sure it is an object
	var user_token = req.param('token')
	if(typeof user_token === 'string') user_token = JSON.parse(user_token)

	switch (req.param('service')) {

		// 
		// Dropbox authentication
		// 

		case "dropbox":
			// Check user exists
			if(users.dropbox.hasOwnProperty(user_token.oauth_token)) {
				var user = users.dropbox[user_token.oauth_token]
				if(user.token_secret === user_token.oauth_token_secret) {
					if(user.hasOwnProperty('uid')) {
						// Check token
						dbox.accesstoken(user_token, function (status, access_token) {
							// Token is good :D
							if (status === 200) {
								dbox.client(access_token).account(function (status, reply) {					
									// Send access token to client so they can use it again
									res.json({
										access: access_token,
										email: reply.email
									})
									delete users.dropbox[user_token.oauth_token]
								})
							} else res.json('failed')
						})
					} else res.json('not_verified')
				} else res.json('failed')
			} else res.json('failed')
			break


		// 
		// Ubuntu authentication
		//

		 case "ubuntu":

		 		// Check user exists
				if(users.ubuntu.hasOwnProperty(user_token.oauth_token)) {
					var user = users.ubuntu[user_token.oauth_token]
					// Check token secret matches
					if(user.request_secret === user_token.oauth_secret) {
						// Check token is verified
						if(user.hasOwnProperty('oauth_secret')) {
							// Check token and get email
							ubuntu.get("https://one.ubuntu.com/api/account/", user.oauth_token, user.oauth_secret, function (e, d, r) {
								if(!e) {
									d = JSON.parse(d)
									res.json({
										access: {
											oauth_token: user.oauth_token, 
											oauth_secret: user.oauth_secret
										},
										email: d.email
									});
									delete users.ubuntu[user_token.oauth_token]
								} else res.json('failed')
							})
						} else res.json('not_verified')
					} else res.json('failed')
				} else res.json('failed')
			break

		// 
		// Debug mode
		// 

		case "debug":

			res.json({
				access: {
					oauth_token: 'foo',
					oauth_secret: 'bar'
				},
				email: 'johnsmith@example.com'
			})
	}
}

function sync(req, res) {
	var service = req.param('service'),
		user;
	
	var access_token = req.param('access');
	if(typeof access_token === 'string') access_token = JSON.parse(access_token);
	
	// Get client
	switch (service) {
		case "dropbox":
			user = dbox.client(access_token)
			break
		case "ubuntu":
			user = access_token
			break
		case "debug":
			user = "John Smith"
			break
	}
	
	getServer(service, user, function(server) {
	
		if(server != 'error') {

			var recievedData = decompress(JSON.parse(req.param('data')));

			// Merge data
			mergeDB(server, recievedData, function (server, error) {

				// Send data back to client
				res.json(compress(server));

				// Don't save if we get an error
				if(!error) {
					saveServer(service, user, server);
				}	
				
				if(!settings.debugMode) {
					//Analytics
					var options = {
						host: 'nitrotasks.com',
						port: 80,
						path: '/analytics/server.php?fingerprint=' + recievedData.stats.uid + '&backend=' + service + '&version=' + recievedData.stats.version + '&os=' + recievedData.stats.os + '&language=' + recievedData.stats.language + '&time=' + Date.now()
					};
		
					require('http').get(options, function() {});
				}
			});
				
		} else {
	
			res.json("error");
	
		}
	});
}

function getServer(service, user, callback) {

	switch (service) {
	case "dropbox":
		user.get(settings.filename, function (status, reply) {
			reply = decompress(JSON.parse(reply.toString()));
			// Check if file exists
			if (!reply.hasOwnProperty('tasks')) {
				server = clone(emptyServer);
				saveServer(service, user, server);
				callback(server);
			} else if (status != 200) {
				callback('error');
			} else {
				callback(reply);
			}
		});
		break;
	case "ubuntu":
		ubuntu.get("https://files.one.ubuntu.com/content/~/Ubuntu%20One/Nitro/" + settings.filename, user.oauth_token, user.oauth_secret, function (e, d, r) {
			if(e) {
				server = clone(emptyServer);
				saveServer(service, user, server);
				callback(server);
			} else {
				reply = decompress(JSON.parse(d.toString()));
				callback(reply);
			}
		});
		break;
	case "debug":
		if(settings.debugMode) {
			fs.readFile('debug/server.txt', function(err, data) {
				if(err) {
					server = clone(emptyServer)
					saveServer(service, user, server)
					callback(server)
				} else {
					callback(JSON.parse(data))
				}
			})
		}
	}
}

function saveServer(service, user, server) {

	var output = JSON.stringify(compress(server)),
		todo = todo_txt_gen(server);

	switch (service) {
	case "dropbox":
		user.put(settings.filename, output, function () {});
		user.put(settings.todo, todo, function () {});
		break;
	case "ubuntu":
		ubuntu.put("https://files.one.ubuntu.com/content/~/Ubuntu%20One/Nitro/" + settings.filename, user.oauth_token, user.oauth_secret, output, "application/json");
		break
	case "debug":
		if(settings.debugMode) {
			fs.writeFile('debug/server.txt', JSON.stringify(server, null, 4))
		}
		break
	}
}

function compress(obj) {
	var chart = {
		name :       'a',
		tasks:       'b',
		content:     'c',
		priority:    'd',
		date:        'e',
		today:       'f',
		showInToday: 'g',
		list:        'h',
		lists:       'i',
		logged:      'j',
		time:        'k',
		sync:        'l',
		synced:      'm',
		order:       'n',
		queue:       'o',
		length:      'p',
		notes:       'q',
		items:       'r',
		next:        's',
		someday:     't',
		deleted:     'u',
		logbook: 	 'v',
		scheduled: 	 'w',
		version: 	 'x',
		tags:  		 'y'
	},
	out = {};

	for (var key in obj) {
		if (chart.hasOwnProperty(key)) {
			out[chart[key]] = obj[key];
			if (typeof obj[key] === 'object' && isArray(obj[key]) == false) {
				out[chart[key]] = compress(out[chart[key]]);
			}
		} else {
			out[key] = obj[key];
			if (typeof obj[key] === 'object' && isArray(obj[key]) == false) {
				out[key] = compress(out[key]);
			}
		}
	}
	return out;
}

function decompress(obj) {
	var chart = {
		a: 'name',
		b: 'tasks',
		c: 'content',
		d: 'priority',
		e: 'date',
		f: 'today',
		g: 'showInToday',
		h: 'list',
		i: 'lists',
		j: 'logged',
		k: 'time',
		l: 'sync',
		m: 'synced',
		n: 'order',
		o: 'queue',
		p: 'length',
		q: 'notes',
		r: 'items',
		s: 'next',
		t: 'someday',
		u: 'deleted',
		v: 'logbook',
		w: 'scheduled',
		x: 'version',
		y: 'tags'
	},
	out = {};

	for (var key in obj) {
		if (chart.hasOwnProperty(key)) {
			out[chart[key]] = obj[key];
			if (typeof obj[key] === 'object' && isArray(obj[key]) == false) {
				out[chart[key]] = decompress(out[chart[key]]);
			}
		} else {
			out[key] = obj[key];
			if (typeof obj[key] === 'object' && isArray(obj[key]) == false) {
				out[key] = decompress(out[key]);
			}
		}
	}
	return out;
}

function todo_txt_gen(db) {

	var convert_date_for_jono = function(timestamp) {
		if (timestamp != "") {
			var date = new Date(timestamp)
			return "due:" + date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate() + " "
		}
		return ""
	}
	var popall = function() {
		var results = [];
		// Loop
		for (var i in db.tasks) {
			if (typeof(db.tasks[i]) == 'object' && !db.tasks[i].hasOwnProperty('deleted') && !db.tasks[i].logged) {
				results.push(i)
			}
		}
		return results
	}
	var textfile = "",
		sorted = sort(db, popall(), 'magic');

	for (var i = 0; i < sorted.length; i++) {

		if (typeof(sorted[i]) !== 'string') continue;

		// Makes it easy
		var id = sorted[i];
		var task = db.tasks[id];

		//Adds Priority
		switch(task.priority) {
			case 'high':
				textfile += '(A) '
				break
			case 'medium':
				textfile += '(B) '
				break
			case 'low':
				textfile += '(C) '
				break
		}

		//Adds Content
		textfile += task.content + " "

		//List
		var list = ""
		if (task.list == 'today' || task.list == 'next') {
			list = task.list
		} else {
			list = db.lists.items[task.list].name
		}
		textfile += "@" + list + " "

		//Date
		textfile += convert_date_for_jono(task.date)

		//Tags
		for (var t = 0; t < task.tags; t++) {
			textfile += "+" + task.tags[t] + " ";
		}

		textfile += "\n"
	}
	return textfile
}

var sort
(function() {

	var priorityWorth = { none: 0, low: 1, medium: 2, high: 3 };

	var getDateWorth = function(timestamp) {

		if(timestamp == "") {
			return 0;
		}

		var due = new Date(timestamp),
			today = new Date();

		// Copy date parts of the timestamps, discarding the time parts.
		var one = new Date(due.getFullYear(), due.getMonth(), due.getDate());
		var two = new Date(today.getFullYear(), today.getMonth(), today.getDate());
		
		// Do the math.
		var millisecondsPerDay = 1000 * 60 * 60 * 24;
		var millisBetween = one.getTime() - two.getTime();
		var days = millisBetween / millisecondsPerDay;
		
		// Round down.
		var diff = Math.floor(days)

		if(diff > 14) {
			diff = 14
		}

		return 14 - diff + 1;

	}
	
	sort = function(db, array, method) {

		// Clone list
		var list = array.slice(0)

		// Convert task IDs to obects
		for(var i = 0; i < list.length; i++) {
			var id = list[i];
			list[i] = db.tasks[list[i]];
			list[i].arrayID = id;
		}
		
		// Sorting methods
		switch(method) {
			
			case "magic":
				list.sort(function(a, b) {

					var rating = {
						a: getDateWorth(a.date),
						b: getDateWorth(b.date)
					}

					var worth = { none: 0, low: 2, medium: 4, high: 6 }

					rating.a += worth[a.priority]
					rating.b += worth[b.priority]

					if(a.logged && !b.logged) return 1
					else if(!a.logged && b.logged) return -1
					else if(a.logged && b.logged) return 0

					return rating.b - rating.a
	
				})
				break
				
			case "manual":
				break;
				
			case "priority":
				
				list.sort(function(a,b) {
					if(a.logged && !b.logged) return 1
					else if(!a.logged && b.logged) return -1
					else if(a.logged && b.logged) return 0
					return priorityWorth[b.priority] - priorityWorth[a.priority]
				});
				break;
				
			case "date":
				list.sort(function(a,b) {
					if(a.logged && !b.logged) return 1
					else if(!a.logged && b.logged) return -1
					else if(a.logged && b.logged) return 0
					// Handle tasks without dates
					if(a.date=="" && b.date !== "") return 1;
					else if(b.date=="" && a.date !== "") return -1;
					else if (a.date == "" && b.date == "") return 0;
					// Sort by priority if dates match
					if (a.date == b.date) return priorityWorth[b.priority] - priorityWorth[a.priority];
					// Sort timestamps
					return a.date -  b.date
				});
				break;
			
		}
		
		// Unconvert task IDs to obects
		for(var i = 0; i < list.length; i++) {
			var id = list[i].arrayID
			delete list[i].arrayID
			list[i] = id
		}
		
		return list;
		
	}
})();
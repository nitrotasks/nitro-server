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

console.info('Nitro Sync 1.4\nCopyright (C) 2012 Caffeinated Code\nBy George Czabania & Jono Cooper');

settings = {
	version: "1.4",
	filename: 'nitro_data.json',
	url: 'http://localhost:3000',
	timeout: 180 // How long the server will wait for the user to authenticate Nitro.
}

// Node Packages
var express = require('express'),
	app = express.createServer(),
	dbox = require("dbox").app({ "app_key": "da4u54t1irdahco", "app_secret": "3ydqe041ogqe1zq" }),
	OAuth = require("oauth").OAuth,
	merge = require('./merge'),
	upgrade = require('./upgrade')

// Ubuntu one settings
var ubuntu = new OAuth("https://one.ubuntu.com/oauth/request/", "https://one.ubuntu.com/oauth/access/", "ubuntuone", "hammertime", "1.0", settings.url + "/ubuntu-one/", "PLAINTEXT"),
	users = {dropbox: {}, ubuntu: {}};

//Funky Headers =)
app.use(function (req, res, next) {
	res.header("X-powered-by", "Windows 95");
	next();
});

// Enable cross browser ajax
app.enable("jsonp callback");
app.use(express.bodyParser());

// Handles Static HTTP Requests
app.use(express.static(__dirname + '/app'));

// Initial Auth
app.post('/auth/', function (req, res) {
	authenticate(req, res);
});

// Actual Sync
app.post('/sync/', function (req, res){
	sync(req, res);
});



// FUNCTIONS
isArray = function(obj) { return obj.constructor == Array }
isObject = function(obj) { return obj.constructor == Object }
isNumber = function(obj) { return !isNaN(parseFloat(obj)) && isFinite(obj) }
clone = function(obj) { return JSON.parse(JSON.stringify(obj)) }
ArrayDiff = function(a,b) { return a.filter(function(i) {return !(b.indexOf(i) > -1)})}

// Remap console.log() to msg()
msg = console.log



// Dropbox callback
app.get('/dropbox', function (req, res) {
	res.send('<meta HTTP-EQUIV="REFRESH" content="0; url='+settings.url+'/success/">');
	var uid = req.query.uid,
		token = req.query.oauth_token;
		if(users.dropbox.hasOwnProperty(token)) {
			users.dropbox[token].uid = uid;
		}
});

// Ubuntu callback for oauth verifier
app.get('/ubuntu-one/', function (req, res) {
	res.send('<meta HTTP-EQUIV="REFRESH" content="0; url='+settings.url+'/success/">');
	var token = req.query.oauth_token;
	if(users.ubuntu.hasOwnProperty(token)) {
		ubuntu.getOAuthAccessToken(token, users.ubuntu[token].request_secret, req.query.oauth_verifier, function(e, t, s, r) {
			users.ubuntu[token].oauth_token = t;
			users.ubuntu[token].oauth_secret = s;
		});
	}
});

port = process.env.PORT || 3000;
app.listen(port);

function authenticate(req, res) {
	// If the client has never been connected before
	if (req.param('reqURL')) {
	
		switch (req.param('service')) {
		case "dropbox":
			// Request a token from dropbox
			dbox.request_token(function (status, request_token) {
	
				request_token.authorize_url += "&oauth_callback=" + settings.url + "/dropbox";
	
				// Send it to the client
				res.json(request_token);
			});
			break;
		case "ubuntu":
			// Request a token from ubuntu one
			ubuntu.getOAuthRequestToken(function(e, t, s, r){
				var reply = {};
				reply.oauth_token = t;
				reply.oauth_secret = s;
				reply.authorize_url = 'https://one.ubuntu.com/oauth/authorize/?description=Nitro&oauth_token=' + t;
				res.json(reply);
			});
			break;
		}
	
	// Client has a token but not oauth
	} else if (req.param('token')) {
	
		// Get token and make sure it is an object
		var user_token = req.param('token');
		if(typeof user_token === 'string') user_token = JSON.parse(user_token);
	
		switch (req.param('service')) {
		case "dropbox":
	
			// Add user
			users.dropbox[user_token.oauth_token] = {};
			var count = 0;
			var check = function () {
	
				if(users.dropbox[user_token.oauth_token].hasOwnProperty('uid')) {
					// Check token
					dbox.access_token(user_token, function (status, access_token) {
						// Token is good :D
						if (status === 200) {
							dbox.createClient(access_token).account(function (status, reply) {						
								// Send access token to client so they can use it again
								res.json({
									access: access_token,
									email: reply.email
								});
								delete users.dropbox[user_token.oauth_token];
							});
						}
					});
				// Nitro hasn't been allowed yet :(
				} else {
					count++;
					// Try again in a second
					if(count <= settings.timeout) setTimeout(check, 1000);
					else res.json('failed')
				}
			}
			check();
			break;
		 case "ubuntu":
			// Add user
			users.ubuntu[user_token.oauth_token] = {request_secret: user_token.oauth_secret};
			var count = 0;
			// Keep checking database
			var check = function() {
				if(users.ubuntu[user_token.oauth_token].hasOwnProperty('oauth_token')) {
					ubuntu.get("https://one.ubuntu.com/api/account/", users.ubuntu[user_token.oauth_token].oauth_token, users.ubuntu[user_token.oauth_token].oauth_secret, function (e, d, r) {
						d = JSON.parse(d);
						res.json({
							access: {
								oauth_token: users.ubuntu[user_token.oauth_token].oauth_token, 
								oauth_secret: users.ubuntu[user_token.oauth_token].oauth_secret
							},
							email: d.email
						});
						delete users.ubuntu[user_token.oauth_token];
					});
				} else {
					count++;
					// Try again in a second
					if(count <= settings.timeout) setTimeout(check, 1000)
					else res.json('failed')
				}
			}
			check();
			break;
		 }
	// Server has been authorised before
	} else if (req.param('access')) {

		var access_token = req.param('access');
		if(typeof access_token === 'string') access_token = JSON.parse(access_token);
	
		switch (req.param('service')) {
	
		case "dropbox":
	
			// Create client
			user = dbox.createClient(access_token);
	
			// Check to see if it worked
			user.account(function (status, reply) {
				if (status === 200) {
					res.json("success");
				} else {
					res.json("failed");
				}
			});
			break;
	
		case "ubuntu":
	
			// Check to see if it worked
			ubuntu.get("https://one.ubuntu.com/api/account/", access_token.oauth_token, access_token.oauth_secret, function (e, d, r) {
				if(e) {
					res.json("failed");
				} else {
					res.json("success");
				}
			});		
			break;
		}
	}
}

function sync(req, res) {
	var service = req.param('service');
	
	var access_token = req.param('access');
	if(typeof access_token === 'string') access_token = JSON.parse(access_token);
	
	// Get client
	switch (service) {
	case "dropbox":
		user = dbox.createClient(access_token);
		break;
	case "ubuntu":
		user = access_token;
	}
	
	getServer(service, user, function(server) {
	
		if(server != 'error') {
	
			var recievedData = decompress(JSON.parse(req.param('data')));
	
			// Merge data
			mergeDB(server, recievedData, function (server) {

				// Send data back to client
				res.json(compress(server));
				saveServer(service, user, server);
	
				//Analytics
				var options = {
					host: 'nitrotasks.com',
					port: 80,
					path: '/analytics/server.php?fingerprint=' + recievedData.stats.uid + '&backend=' + service + '&version=' + recievedData.stats.version + '&os=' + recievedData.stats.os + '&language=' + recievedData.stats.language
				};
	
				require('http').get(options, function() {});
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
	}

}

function saveServer(service, user, server) {
	var output = JSON.stringify(compress(server));

	switch (service) {
	case "dropbox":
		user.put(settings.filename, output, function () {});
		break;
	case "ubuntu":
		ubuntu.put("https://files.one.ubuntu.com/content/~/Ubuntu%20One/Nitro/" + settings.filename, user.oauth_token, user.oauth_secret, output, "application/json", function (e, d, r) {
			if(e) {
				callback("Error saving file!");
			}
		});
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
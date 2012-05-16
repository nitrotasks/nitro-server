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

console.info('Nitro Sync 1.3\nCopyright (C) 2012 Caffeinated Code\nBy George Czabania & Jono Cooper');

var settings = {
	filename: 'nitro_data.json'
}

// Node Packages
var color = require('./lib/ansi-color').set,
	express = require('express'),
	app = express.createServer(),
	dbox = require("dbox").app({ "app_key": "da4u54t1irdahco", "app_secret": "3ydqe041ogqe1zq" }),
	OAuth = require("oauth").OAuth;
 
// Ubuntu one settings
var ubuntu = new OAuth("https://one.ubuntu.com/oauth/request/", "https://one.ubuntu.com/oauth/access/", "ubuntuone", "hammertime", "1.0", "http://localhost:3000/ubuntu-one/", "PLAINTEXT"),
	users = {};

//Funky Headers =)
app.use(function (req, res, next) {
	res.header("X-powered-by", "NitrOS 2000");
	next();
});

// Enable cross browser ajax
// app.enable("jsonp callback");
app.use(express.bodyParser());



// Handles Static HTTP Requests
app.use(express.static(__dirname + '/site'));

// Initial Auth
app.post('/auth/', function (req, res) {

	console.log(color("** Starting Auth **", "blue"));

	// If the client has never been connected before
	if (req.param('reqURL')) {

		switch (req.param('service')) {
		case "dropbox":
			// Request a token from dropbox
			dbox.request_token(function (status, request_token) {
				console.log(color("Sending authorize_url", "blue"));

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
				reply.authorize_url = 'https://one.ubuntu.com/oauth/authorize/?oauth_token=' + t;
				res.json(reply);
			});
			break;
		}

	// Client has a token but not oauth
	} else if (req.param('token')) {

		switch (req.param('service')) {
		case "dropbox":
		
			var count = 0, max = 20;

			var checkServer = function () {
				console.log(color('Connecting to dropbox', "blue"));

				// Check token
				dbox.access_token(req.param('token'), function (status, access_token) {

					// Token is good :D
					if (status === 200) {
						console.log(color('Attempt ' + count + ' - Connected!', "yellow"));

						// Send access token to client so they can use it again
						res.json(access_token);

					// Nitro hasn't been allowed yet :(
					} else {
						console.log(color('Attempt ' + count + ' - Failed!', "red"));
						count++;

						// Try again in a second
						if(count <= max) setTimeout(checkServer, 1000);
					}
				});
			}

			checkServer();
			break;


		 case "ubuntu":

			var user_token = req.param('token');

			// Add user
			users[user_token.oauth_token] = {request_secret: user_token.oauth_secret};

			console.log(users)

			// Keep checking database
			var check = function() {
				if(users[user_token.oauth_token].hasOwnProperty('oauth_token')) {
					res.json({oauth_token: users[user_token.oauth_token].oauth_token, oauth_secret: users[user_token.oauth_token].oauth_secret});
					delete users[user_token.oauth_token];
				} else {
					console.log("failed, trying again")
					setTimeout(check, 1000);
				}
			}
			
			check();
			
			break;
		 }

	// Server has been authorised before
	} else if (req.param('access')) {

		console.log(color("Using client stored key", "blue"));

		switch (req.param('service')) {

		case "dropbox":

			// Create client
			user = dbox.createClient(req.param('access'));

			// Check to see if it worked
			user.account(function (status, reply) {
				if (status === 200) {
					console.log(color("Connected!", "yellow"));
					res.json("success");
				} else {
					console.log(color("Could not connect :(", "red"));
					res.json("failed");
				}
			});
			break;

		case "ubuntu":

			// Check to see if it worked
			ubuntu.get("https://one.ubuntu.com/api/account/", req.param('access').oauth_token, req.param('access').oauth_secret, function (e, d, r) {
				if(e) {
					res.json("failed");
				} else {
					res.json("success");
				}
			});		
			break;
		}
	}
});

// Ubuntu callback for oauth verifier
app.get('/ubuntu-one/', function (req, res) {
	res.send("Authentication Complete!");

	console.log("Requesting access token");

	var token = req.query.oauth_token;

	if(users.hasOwnProperty(token)) {
		console.log("Token found :D Going to try and get access token");
		ubuntu.getOAuthAccessToken(token, users[token].request_secret, req.query.oauth_verifier, function(e, t, s, r) {
			users[token].oauth_token = t;
			users[token].oauth_secret = s;
			console.log(users);
		});
	} else {
		console.log("ERROR: Token not found!?")
	}
});

// Actual Sync
app.post('/sync/', function (req, res){

	var service = req.param('service');

	// Get client
	switch (service) {
	case "dropbox":
		user = dbox.createClient(req.param('access'));
		break;
	case "ubuntu":
		user = req.param('access');
	}
	
	getServer(service, user, function(server) {

		if(server != 'error') {

			// Merge data
			merge(server, decompress(JSON.parse(req.param('data'))), function (server) {
				// Send data back to client
				console.log(JSON.stringify(server, null, 4));
				console.log("Merge complete. Updating client.");
				res.json(compress(server));
				saveServer(service, user, server);
			});

		} else {
			
			console.log("We got an error!")

			res.json("error");

		}
	});

	
});

port = process.env.PORT || 3000;
app.listen(port);

function getServer(service, user, callback) {
	console.log(color("Getting File from server", 'blue'));

	switch (service) {
	case "dropbox":
		console.log("Dropbox")
		user.get(settings.filename, function (status, reply) {
			reply = decompress(JSON.parse(reply.toString()));

			// Check if file exists
			if (!reply.hasOwnProperty('tasks')) {
				console.log(color("File doesn't exist on the clients dropbox :(", 'red'));
				console.log(color("So let's make one :D", 'blue'));
				server = clone(emptyServer);
				saveServer(service, user, server);
				callback(server);
			} else if (status != 200) {
				callback('error');
			} else {
				console.log(color("Got the server!", 'yellow'));
				callback(reply);
			}
		});
		break;
	case "ubuntu":
		console.log("Ubuntu")
		ubuntu.get("https://files.one.ubuntu.com/content/~/Ubuntu%20One/Nitro/" + settings.filename, user.oauth_token, user.oauth_secret, function (e, d, r) {
			if(e) {
				console.log(e);
				console.log(color("File doesn't exist on the client's ubuntu one account :(", 'red'));
				console.log(color("So let's make one :D", 'blue'));
				server = clone(emptyServer);
				saveServer(service, user, server);
				callback(server);
			} else {
				reply = decompress(JSON.parse(d.toString()));
				console.log(color("Got the server!", 'yellow'));
				callback(reply);
			}
		});
		break;
	}
	
}

function saveServer(service, user, server) {
	console.log(color("Saving to server (starting)", 'blue'));
	var output = JSON.stringify(compress(server));

	switch (service) {
	case "dropbox":
		console.log("Dropbox");
		user.put(settings.filename, output, function () {
			console.log(color("Saving to server (complete!)", 'yellow'));
		});
		break;
	case "ubuntu":
		ubuntu.put("https://files.one.ubuntu.com/content/~/Ubuntu%20One/Nitro/" + settings.filename, user.oauth_token, user.oauth_secret, output, "application/json", function (e, d, r) {
			if(e) {
				callback("Error saving file!");
			} else {
				console.log(color("Saving to server (complete!)", 'yellow'));
			}
		});
	}
}

// Create server
var emptyServer = {
	tasks: {
		length: 0
	},
	lists: {
		order: [],
		items: {
			0: {
				order: []
			},
			today: {
				name: "Today",
				order: [],
				time: {
					name: 0,
					order: 0
				}
			},
			next: {
				name: "Next",
				order: [],
				time: {
					name: 0,
					order: 0
				}
			},
			length: 1
		},
		time: 0,
		scheduled: {
			length: 0
		},
		deleted: {}
	},
	queue: {}
};

function merge(server, client, callback) {

	console.log(color(JSON.stringify(client), 'yellow'));
	console.log(color(JSON.stringify(server), 'cyan'));

	var cli = {
		timestamp: {
			update: function (id, key) {
				return {
					task: function () {
						server.tasks[id].time[key] = Date.now();
						// cli.timestamp.sync();
					},
					list: function () {
						if (id !== 0) {
							server.lists.items[id].time[key] = Date.now();
							// cli.timestamp.sync();
						}
					},
					scheduled: function () {
						server.lists.scheduled[id].time[key] = Date.now();
						// cli.timestamp.sync();
					}
				};
			},
			sync: function () {
				if (server.prefs.sync === 'auto') {
					ui.sync.running();
					server.sync();
				} else {
					ui.sync.active();
				}
			},
			upgrade: function () {
	
				var passCheck = true;
	
				// Check tasks for timestamps
				for(var id in server.tasks) {
					if (id !== 'length' && !server.tasks[id].hasOwnProperty('deleted')) {
	
						// Check task has time object
						if (!server.tasks[id].hasOwnProperty('time')) {
							console.log("Upgrading task: '" + id + "' to Nitro 1.1 (timestamps)");
							passCheck = false;
	
							server.tasks[id].time = {
								content: 0,
								priority: 0,
								date: 0,
								notes: 0,
								today: 0,
								showInToday: 0,
								list: 0,
								logged: 0
							};
						}
	
						// Check task has sync status
						if (!server.tasks[id].hasOwnProperty('synced')) {
							console.log("Upgrading task: '" + id + "' to Nitro 1.1 (sync)");
							passCheck = false;
	
							server.tasks[id].synced = false;
						}
						break;
					}
				}
	
				// Check lists for timestamps
				for(var id in server.lists.items) {
					if (id !== 'length' && id !== '0') {
	
						// Check list has time object
						if (!server.lists.items[id].hasOwnProperty('time') || typeof(server.lists.items[id].time) === 'number') {
							console.log("Upgrading list: '" + id + "' to Nitro 1.2 (timestamp)");
							passCheck = false;
	
							// Add or reset time object
							server.lists.items[id].time = {
								name: 0,
								order: 0
							};						
						}
	
						if (id !== 'today' && id !== 'next' && id !== 'someday') {
							// Check list has synced status
							if (!server.lists.items[id].hasOwnProperty('synced')) {
								console.log("Upgrading list: '" + id + "' to Nitro 1.2 (sync)");
								passCheck = false;
	
								server.lists.items[id].synced = 'false';
							}
						}
	
						// Convert everything to numbers
						for  (var x = 0; x < server.lists.items[id].order.length; x++) {
							if(typeof server.lists.items[id].order[x] === 'string') {
								server.lists.items[id].order[x] = server.lists.items[id].order[x].toNum();
							}
						}
					}
				}
	
				//Check someday list
				if (server.lists.items.someday) {
					console.log('Upgrading DB to Nitro 1.3');
					//Create Someday List
					cli.list('', 'Someday').add();
	
					for (var key in server.lists.items.someday.order) {
						//Moves Tasks into New List
						cli.moveTask(server.lists.items.someday.order[key], server.lists.items.length - 1);
					}
	
					delete server.lists.items.someday;
					// server.save();
				}
	
				//Check for scheduled
				if (!server.lists.scheduled) {
					server.lists.scheduled = {length: 0};
				}
	
				// Check preferences exist. If not, set to default
				server.lists.deleted = server.lists.deleted   || {};
				server.lists.time     = server.prefs.time     || 0;
				server.prefs.sync     = server.prefs.sync     || 'manual';
				server.prefs.lang     = server.prefs.lang     || 'english';
				server.prefs.bg       = server.prefs.bg       || {};
				server.prefs.bg.color = server.prefs.bg.color || '';
				server.prefs.bg.size  = server.prefs.bg.size  || 'tile';
	
				// Save
				// server.save();
	
				if (passCheck) {
					// Database is up to date
					console.log("Database is up to date")
				} else {
					// Database was old
					console.log("Database was old")
	
					if (app == 'js') {
						console.log("Regex all the things!")
	
						//Regexes for funny chars
						localStorage.jStorage = localStorage.jStorage.replace(/\\\\/g, "&#92;").replace(/\|/g, "&#124").replace(/\\"/g, "&#34;").replace(/\'/g, "&#39;");
	
						//Reloads jStorage
						$.jStorage.reInit()
					}
				}
			}
		},
		escape: function (str) {
			//Regexes a bunch of shit that breaks the Linux version
	
			if (typeof str === 'string') {
				str = str
					.replace(/\\/g, "&#92;") // Backslash
					.replace(/\|/g, "&#124") // Pipe
					.replace(/\"/g, "&#34;") // Quote
					.replace(/\'/g, "&#39;"); // Apostrophe
				return str;
			} else {
				return str;
			}
	
		},
		addTask: function (name, list) {
			name = cli.escape(name);
			// Creates a task
	
			//Id of task
			var id = server.tasks.length;
			server.tasks.length++;
	
			//Saves to Localstorage
			server.tasks[id] = {
				content: name,
				priority: 'none',
				date: '',
				notes: '',
				today: 'false',
				showInToday: '1',
				list: list,
				logged: false,
				time: {
					content: 0,
					priority: 0,
					date: 0,
					notes: 0,
					today: 0,
					showInToday: 0,
					list: 0,
					logged: 0
				},
				synced: false
			};
	
			if (list === 'today') {
				cli.today(id).add();
			} else {
				//Pushes to array
				server.lists.items[list].order.unshift(id);
			}
	
			// Timestamp (list order)
			// cli.timestamp.update(list, 'order').list();
	
			//Saves to disk
			// server.save();
	
			//Returns something
			console.log("Created Task: '" + name + "' with id: " + id + " in list: " + list);
	
		},
		deleteTask: function (id) {
	
			//If it's a recurring or scheduled task
			if (id.substr(0,1) === 'r'  || id.substr(0,1) == 's') {
				delete server.lists.scheduled[id.substr(1)];
				// server.save();
			} else {
				var task = cli.taskData(id).display();
	
				// Timestamp (list order)
				// cli.timestamp.update(task.list, 'order').list();
	
				cli.calc.removeFromList(id, task.list);
	
				//Changes task List to 0 so today.calculate removes it.
				task.list = 0;
				cli.taskData(id).edit(task);
	
				//Removes from Today and Next
				cli.today(id).calculate();
	
				//Removes from list
				cli.calc.removeFromList(id, 0);
	
				//Deletes Data
				server.tasks[id] = { deleted: Date.now() };
	
				//Saves
				// server.save();
			}
		},
		populate: function (type, query, searchlist) {
			query = cli.escape(query);
			// Displays a list
			switch(type) {
				case "list":
					// Get tasks from list
	
					if (query === 'logbook') {
						var logbook = [];
	
						for (var t = 0; t < server.tasks.length; t++) {
							// looooooping through the tasks
							if (server.tasks[t]) {
								if (server.tasks[t].logged) {
									var data = cli.taskData(t).displaysay();
									//remove today & date data
									data.date = '';
									data.today = 'false';
									cli.taskData(t).edit(data);
	
									logbook.push(t);
								}
							}
						}
	
						return logbook;
	
					} else if (query === 'all') {
	
						var results = [];
	
						// Search loop
						for (var t = 0; t < server.tasks.length; t++) {
	
							// If task exists
							if (server.tasks[t]) {
	
								// Exclude logged tasks
								if (server.tasks[t].logged == false || server.tasks[t].logged == 'false') {
									results.push(t);
								}
							}
						}
						return results;
					} else if (query === 'scheduled') {
						var results = []
						for (key in server.lists.scheduled) {
							//Pushes Results
							if (server.lists.scheduled[key].type === 'scheduled') {
								results.push('s' + key);
							} else if (server.lists.scheduled[key].type === 'recurring') {
								results.push('r' + key);
							};
						};
						return results;
					} else {
	
						if (query in server.lists.items) {
							return server.lists.items[query].order;
						} else {
							return [];
						}
	
					}
	
					break;
	
				case "search":
					// Run search
	
					// Set vars
					var query = query.split(' '),
						results = [],
						search;
	
					function searcher(key) {
						var pass1 = [],
							pass2  = true;
	
						// Loop through each word in the query
						for (var q = 0; q < query.length; q++) {
	
							// Create new search
							search = new RegExp(query[q], 'i');
	
							// Search
							if (search.test(server.tasks[key].content + server.tasks[key].notes)) {
								pass1.push(true);
							} else {
								pass1.push(false);
							}
						}
	
						// This makes sure that the task has matched each word in the query
						for (var p = 0; p < pass1.length; p++) {
							if (pass1[p] === false) {
								pass2 = false;
							}
						}
	
						// If all terms match then add task to the results array
						if (pass2) {
							return (key)
						}
					}
	
					if (searchlist == 'all') {
						// Search loop
						for (var t = 0; t < server.tasks.length; t++) {
	
							// If task exists
							if (server.tasks[t]) {
	
								// Exclude logged tasks
								if (server.tasks[t].logged == false || server.tasks[t].logged == 'false') {
	
									//Seaches Task
									var str = searcher(t);
									if (str != undefined) {
										results.push(str);
									}				
								}
							}
						}
					} else if (searchlist == 'logbook') {
						//Do Something
						for (var t = 0; t < server.tasks.length; t++) {
	
							// If task exists
							if (server.tasks[t]) {
	
								// Exclude logged tasks
								if (server.tasks[t].logged == true || server.tasks[t].logged == 'true') {
	
									//Seaches Task
									var str = searcher(t);
									if (str != undefined) {
										results.push(str);
									}				
								}
							}
						}
					} else if (searchlist == 'scheduled') {
	
					} else {
						for (var key in server.lists.items[searchlist].order) {
							var str = parseInt(searcher(server.lists.items[searchlist].order[key]))
							if (!isNaN(str)) {
								results.push(str);
							}
						}
					}
					return results;
			}
		},
		moveTask: function (id, list) {
			// Moves task to list
	
			var task = cli.taskData(id).display(),
				lists = server.lists.items;
	
			// Remove task from old list
			cli.calc.removeFromList(id, task.list);
	
			// Add task to new list
			lists[list].order.push(id);
	
			// Update timestamp
			// cli.timestamp.update(id, 'list').task();
			// cli.timestamp.update(task.list, 'order').list();
			// cli.timestamp.update(list, 'order').list();
	
			// Update task.list
			task.list = list;
	
			cli.today(id).calculate();
	
			//If it's dropped in Someday, we strip the date & today
			if (list === 'someday') {
				task.date = '';
				cli.today(id).remove();
			}
	
			// Save
			cli.taskData(id).edit(task);
			server.lists.items = lists;
			// server.save();
	
			console.log('The task with the id: ' + id + ' has been moved to the ' + list + ' list');
		},
		today: function (id) {
			return {
				add: function () {
					// Adds to Today Manually
					var task = cli.taskData(id).display();
	
					task.today = 'manual';
					task.showInToday = '1';
					cli.today(id).calculate();
	
				},
				remove: function () {
					// Removes from Today Manually
					var task = cli.taskData(id).display();
	
					task.today = 'false';
					task.showInToday = 'none';
	
					if (task.list === 'today') {
						task.list = 'next';
					}
	
					cli.today(id).calculate();
				},
				calculate: function () {
					/* This is the function that I wish I had.
					Removes from today or next then
					Depending on the due date etc, the function chucks it into today, next etc */
	
					// Removes from Today & Next
					var task = cli.taskData(id).display(),
						lists = server.lists.items;
	
					// Remove task from Today
					cli.calc.removeFromList(id, 'today');
	
					// Remove task from Next
					cli.calc.removeFromList(id, 'next');
	
					console.log('List: ' + task.list);
					// cli.timestamp.update(id, 'showInToday').task();
					// cli.timestamp.update(id, 'list').task();
	
					// Update timestamp
					// cli.timestamp.update(id, 'today').task();
	
					//If the task is due to be deleted, then delete it
					if (task.list === 0) {
						return;
					}
	
					//If task is in logbook, do nothing
					if (task.logged) {
						return;
					}
	
					//Calculates date. Changes today Status
					cli.calc.date(id);
	
					//If the task.list is today, we place back in today & next
					if (task.list === 'today') {
	
						lists.today.order.unshift(id);
						lists.next.order.unshift(id);
	
						console.log('List in today, placed in today');
					} else {
						//If the task is either manually in today, or has a date, we place in Today and next
						if (task.today === 'manual' || task.today === 'yesAuto') {
							//Adds to Today & Next arrays
							console.log('List either manually set or Date set. In today');
							lists.today.order.unshift(id);
							lists.next.order.unshift(id);
						} else {
							console.log('Not in today');
							//Do nothing unless in Next list
							if (task.list === 'next') {
								//Adds to Next array
								lists.next.order.unshift(id);
							}
						}
					}
	
					// DeDupe today and next lists
					server.lists.items.today.order = deDupe(server.lists.items.today.order);
					server.lists.items.next.order = deDupe(server.lists.items.next.order)
	
					//Saves data
					// server.save();
				}
			};
		},
		logbook: function (id) {
			// Toggles an item to/from the logbook
	
			var task = cli.taskData(id).display(),
				lists = server.lists.items;
	
			// Check if task exists
			if (!task) {
				console.log('No task with id: ' + id + ' exists');
				return;
			}
	
			task.logged = !task.logged;
	
			//If list is deleted, set to next
			if (!(task.list in lists)) {
				task.list = 'next';
			}
	
			if (task.logged) { // Uncomplete -> Complete
				//Gets name of list
				var oldlist = task.list;
	
				//Puts it in List 0 where it goes to die
				cli.moveTask(id, 0);
				cli.calc.removeFromList(id, 0);
	
				//Moves it back to original list
				task.list = oldlist;
	
				console.log("Task with id: " + id + " has been completed");
			} else {
				// Complete -> Uncomplete
	
				// Add task to list
				lists[task.list].order.push(id);
	
				console.log("Task with id: " + id + " has been uncompleted");
			}
	
			// Update timestamp
			// cli.timestamp.update(id, 'logged').task();
	
			cli.taskData(id).edit(task);
			server.lists.items = lists;
			// server.save();
		},
		priority: function (id) {
			return {
				get: function () {
					//Scheduled
					if (typeof(id) != 'number' && id.substr(0,1) === 's' || typeof(id) != 'number' && id.substr(0,1) === 'r') {
						priority = server.lists.scheduled[id.toString().substr(1)].priority;
					} else {
						priority = server.tasks[id].priority;	
					}
					return priority;
				},
				set: function () {
					if (typeof(id) != 'number' && id.substr(0,1) === 's' || typeof(id) != 'number' && id.substr(0,1) === 'r') {
						var priority = server.lists.scheduled[id.toString().substr(1)].priority;
					} else {
						var priority = server.tasks[id].priority;	
					}
					switch(priority) {
						case "low":
							priority = "medium";
							break;
						case "medium":
							priority = "important";
							break;
						case "important":
							priority = "none";
							break;
						case "none":
							priority = "low";
							break;
					}
	
	
	
					if (typeof(id) != 'number' && id.substr(0,1) === 's' || typeof(id) != 'number' && id.substr(0,1) === 'r') {
						// cli.timestamp.update(id.toString().substr(1), 'priority').scheduled();
						server.lists.scheduled[id.toString().substr(1)].priority = priority;
					} else {
						// cli.timestamp.update(id, 'priority').task();
						server.tasks[id].priority = priority;
					}
	
					// server.save();
					return priority;
				}
			};
		},
		taskData: function (id) {
			return {
				display: function () {
					// Returns taskData as object
					return server.tasks[id];
	
				},
				edit: function (obj) {
					// Edit taskData
	
					for(var value in obj) {
						if (typeof obj[value] === 'string') {
							obj[value] = cli.escape(obj[value]);
						}
						if (obj[value] !== $.jStorage.get('tasks')[id][value] && value !== 'time') {
							// cli.timestamp.update(id, value).task();
						}
					}
	
					server.tasks[id] = obj;
					// server.save();
	
				}
			};
		},
		list: function (id, name) {
			name = cli.escape(name);
	
			return {
				add: function () {
					// Adds a list
					var newId = server.lists.items.length;
	
					//Chucks data in object
					server.lists.items[newId] = {
						name: name,
						order: [],
						time: {
							name: 0,
							order: 0
						},
						synced: false
					};
	
					//Adds to order array
					server.lists.order.push(newId);
	
					//Returns something
					console.log("Created List: '" + name + "' with id: " + newId);
	
					// Update timestamp for list order
					server.lists.time = Date.now();
	
					//Updates Total
					server.lists.items.length++;
					// server.save();
				},
				rename: function () {
					// Renames a list
					server.lists.items[id].name = name;
					// cli.timestamp.update(id, 'name').list();
	
					//Saves to localStorage
					// server.save();
	
					//Returns something
					console.log("Renamed List: " + id + " to: '" + name + "'");
				},
				remove: function () {
					//Deletes data in list
					for (var i=0; i<server.lists.items[id].order.length; i++) {
						cli.today(server.lists.items[id].order[i]).remove();
						server.tasks[server.lists.items[id].order[i]] = {deleted: Date.now()};
					}
	
					//Deletes actual list
					delete server.lists.items[id]
					server.lists.deleted[id] = Date.now();
					server.lists.order.splice(jQuery.inArray(id, server.lists.order), 1);
	
					// Update timestamp for list order
					server.lists.time = Date.now();
	
					//Saves to disk
					// server.save();
	
					//Returns something
					console.log("Deleted List: " + id);
				},
				taskOrder: function (order) {
					//Order of tasks
					// cli.timestamp.update(id, 'order').list();
					server.lists.items[id].order = order;
					// server.save();
				},
				order: function (order) {
					// Order of lists
					server.lists.time = Date.now();
					server.lists.order = order;
					// server.save();
				}
			};
		},
		calc: {
			//Another object where calculations are done
			removeFromList: function (id, list) {
	
				var task = cli.taskData(id).display(),
					lists = server.lists.items;
	
				// DOES NOT REMOVE LIST FROM TASK
				// List must be manually removed from task.list
				// task.list = '';
	
				// Remove task from Today
				for(var i = 0; i < lists[list].order.length; i++) {
					if (lists[list].order[i] === id) {
						lists[list].order.splice(i, 1);
						console.log('Removed: ' + id + ' from ' + list);
					}
				}
	
				// cli.taskData(id).edit(task);
				server.lists.items = lists;
				// server.save();
			},
	
			date: function (id) {
				var task = cli.taskData(id).display(),
					lists = server.lists.items;
	
				//If it's already in today, do nothing. If it doesn't have a date, do nothing.
				if (task.today !== 'manual' && task.date !== '') {
					if (task.showInToday === 'none') {
						//Remove from today
						task.today = 'false';
						console.log('Specified to not show in today');
	
						//Remove from queue
						if (server.queue[id]) {
							delete server.queue[id];
						}
	
					} else {
						console.log('Due date, running queue function');
	
						//Due date + days to show in today
						var date = new Date(task.date);
						date.setDate(date.getDate() - parseInt(task.showInToday, 10));
						var final = (date.getMonth() + 1) + '/' + date.getDate() + '/' + date.getUTCFullYear();
	
						server.queue[id] = final;
	
						// server.save();
	
						//Refreshes Date Queue
						cli.calc.todayQueue.refresh();
					}
				}
			},
			dateConvert: function (olddate) {
				//Due date + days to show in today
				var date = new Date(olddate);
				var final = (date.getMonth() + 1) + '/' + date.getDate() + '/' + date.getUTCFullYear();
	
				return final;
			},
			prettyDate: {
				convert: function (date) {
					date = date.split('/');
					date = new Date(date[2], date[0] - 1, date[1]);
					//If it's the current year, don't add the year.
					if (date.getFullYear() === new Date().getFullYear()) {
						date = date.toDateString().substring(4).replace(" 0"," ").replace(" " + new Date().getFullYear(), '');
					} else {
						date = date.toDateString().substring(4).replace(" 0"," ");
					}
					return date;
				},
				difference: function (date) {
	
					if (date === '') {
						return ['', ''];
					} else {
						var	now = new Date(),
							date = date.split('/'),
							difference = 0,
							oneDay = 86400000; // 1000*60*60*24 - one day in milliseconds
	
						// Convert to JS
						date = new Date(date[2], date[0] - 1, date[1]);
	
						// Find difference between days
						difference = Math.ceil((date.getTime() - now.getTime()) / oneDay);
	
						// Show difference nicely
						if (difference < -1) {
							// Overdue
							difference = Math.abs(difference);
							if (difference !== 1) {
								return [$.i18n._('daysOverdue', [difference]), 'overdue'];
							}
						} else if (difference === -1) {
							// Yesterday
							return ["due yesterday", 'due'];
						} else if (difference === 0) {
							// Due
							return ["due today", 'due'];
						} else if (difference === 1) {
							// Due
							return ["due tomorrow", ''];
						} else if (difference < 15) {
							// Due in the next 15 days
							if (difference !== 1) {
								return [$.i18n._('daysLeft', [difference]), ''];
							}
						} else {
							// Due after 15 days
							var month = $.i18n._('month');
							return [month[date.getMonth()] + " " + date.getDate(), ''];
						}
					}
				}
			},
			todayQueue: {
	
				refresh: function () {
	
					for (var key in server.queue) {
						key = Number(key);
						console.log(key +  " -> " + server.queue[key]);
	
						var targetdate = new Date(server.queue[key]);
						var todaydate = new Date();
	
						//Reset to 0:00
						todaydate.setSeconds(0);
						todaydate.setMinutes(0);
						todaydate.setSeconds(0);
	
						//If today is the same date as the queue date or greater, put the task in today and next
						if (todaydate >= targetdate) {
	
							server.tasks[key].today = 'yesAuto';
	
							//Adds to today & next lists
							server.lists.items.today.order.push(key);
	
							//Makes sure it doesn't it doesn't double add to next
							if (server.tasks[key].list !== 'next') {
								server.lists.items.next.order.push(key);
							}
	
							delete server.queue[key];
	
						} else {
							//Wait till tomorrow.
							server.tasks[key].today = 'noAuto';
						}
						// server.save();
					}
				}
			}
		},
	
		scheduled: {
			add: function(name, type) {
				console.log("Added a new " + type + " task")
				if (type === 'scheduled') {
					server.lists.scheduled[server.lists.scheduled.length] = {
						content: name,
						priority: 'none',
						date: '',
						notes: '',
						list: 'today',
						type: 'scheduled',
						next: '0',
						date: '',
						sycned: false,
						time: {
							content: 0,
							priority: 0,
							date: 0,
							notes: 0,
							list: 0,
							type: 0,
							next: 0,
							date: 0
						}
					}
	
				} else if (type === 'recurring') {
					server.lists.scheduled[server.lists.scheduled.length] = {
						content: name,
						priority: 'none',
						date: '',
						notes: '',
						list: 'today',
						type: 'recurring',
						next: '0',
						date: '',
						recurType: 'daily',
						recurInterval: [1],
						ends: '0',
						synced: false,
						time: {
							content: 0,
							priority: 0,
							date: 0,
							notes: 0,
							list: 0,
							type: 0,
							next: 0,
							date: 0,
							recurType: 0,
							recurInterval: 0,
							ends: 0
						}
					}
				}
	
				server.lists.scheduled.length++;
				// server.save();
			},
	
			edit: function(id, obj) {
				//Returns data if nothing is passed to it
				if (obj) {
	
					for(var value in obj) {
						if (typeof obj[value] === 'string') {
							obj[value] = cli.escape(obj[value]);
						}
						if (obj[value] !== $.jStorage.get('lists')[id][value] && value !== 'time') {
							// cli.timestamp.update(id, value).scheduled();
						}
					}
	
					server.lists.scheduled[id] = obj;
					// server.save();
				};
	
				return server.lists.scheduled[id];
			},
	
			update: function() {
				//Loops through all da tasks
				for (var i=0; i < server.lists.scheduled.length; i++) {
	
					//Checks if tasks exists
					if (server.lists.scheduled[i]) {
						var task = server.lists.scheduled[i];
	
						if (task.next != '0') {
	
							//Add the task to the list if the date has been passed
							if (new Date(task.next).getTime() <= new Date().getTime()) {
	
								cli.addTask(task.content, task.list);
								var data = cli.taskData(server.tasks.length -1).display();
	
								//Sets Data
								data.notes = task.notes;
								data.priority = task.priority;
	
								//Task is scheduled
								if (task.type == 'scheduled') {
	
									cli.taskData(server.tasks.length -1).edit(data);
	
									//Deletes from scheduled							
									delete server.lists.scheduled[i];
									console.log('Task: ' + i + ' has been scheduled');
	
								//Task is recurring
								} else if (task.type == 'recurring') {
	
									//Calculates Due Date
									if (task.date != '') {
										//Adds number to next
										var tmpdate = new Date(task.next);
										tmpdate.setDate(tmpdate.getDate() + parseInt(task.date));
										data.date = cli.calc.dateConvert(tmpdate);
	
										//Saves
										cli.taskData(server.tasks.length -1).edit(data);
										cli.calc.date(server.tasks.length -1);
									}
	
									//Change the Next Date
									if (task.recurType == 'daily') {
										var tmpdate = new Date(task.next);
										tmpdate.setDate(tmpdate.getDate() + task.recurInterval[0]);
										task.next = cli.calc.dateConvert(tmpdate);
									} else if (task.recurType == 'weekly') {
										var nextArr = [];
	
										//Loop through everything and create new dates
										for (var key in task.recurInterval) {
											//Checks if date has been passed
											if (new Date(task.recurInterval[key][2]).getTime() <= new Date().getTime()) {
												//If it has, we'll work out the next date.
												task.recurInterval[key][2] = cli.calc.dateConvert(Date.parse(task.recurInterval[key][2]).addWeeks(parseInt(task.recurInterval[key][0]) - 1).moveToDayOfWeek(parseInt(task.recurInterval[key][1])));
											}
	
											//Even if it hasn't, we'll still push it to an array.
											nextArr.push(new Date(task.recurInterval[key][2]).getTime());
										}
										//Next date as the next one coming up
										task.next = cli.calc.dateConvert(Array.min(nextArr));
									} else if (task.recurType == 'monthly') {
										var nextArr = []
	
										//Loop through everything and create new dates
										for (var key in task.recurInterval) {
											//Checks if date has been passed
											if (new Date(task.recurInterval[key][3]).getTime() <= new Date().getTime()) {
												if (task.recurInterval[key][2] == 'day') {
	
													if (Date.today().set({day: task.recurInterval[key][1]}).getTime() <= new Date().getTime()) {
														//If it's been, set it for the next month
														task.recurInterval[key][3] = cli.calc.dateConvert(Date.today().set({day: task.recurInterval[key][1]}).addMonths(1).getTime());
													} else {
														//If it hasn't, set it for this month
														task.recurInterval[key][3] = cli.calc.dateConvert(Date.today().set({day: task.recurInterval[key][1]}).getTime());
													}
												} else {
													console.log('boop')
													var namearr = ['zero', 'set({day: 1})', 'second()', 'third()', 'fourth()', 'last()'];
													var datearr = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
													//Fuckit. Using eval. Stupid date.js
													var result = eval('Date.today().' + namearr[task.recurInterval[key][1]] + '.' + datearr[task.recurInterval[key][2]] + '()')
	
													console.log(result)
	
													//If it's already been, next month
													if (result.getTime() < new Date().getTime()) {
														var result = eval('Date.today().' + namearr[task.recurInterval[key][1]] + '.addMonths(1).' + datearr[task.recurInterval[key][2]] + '()')
													}
	
													task.recurInterval[key][3] = cli.calc.dateConvert(new Date(result));
												}
											}
	
											//Even if it hasn't, we'll still push it to an array.
											nextArr.push(new Date(task.recurInterval[key][3]).getTime());
										}
	
										//Next date as the next one coming up
										task.next = cli.calc.dateConvert(Array.min(nextArr));
	
									}
	
									//Saves
									cli.scheduled.edit(i, task);	
	
									console.log('Task: ' + i + ' has been recurred')
								}
	
								// server.save();
							}
						};
					};
				};
			}
		},
	
		storage: {
			//Object where data is stored
			// tasks: $.jStorage.get('tasks', {length: 0}),
			// queue: $.jStorage.get('queue', {}),
			// lists: $.jStorage.get('lists', {order: [], items:{today: {name: "Today", order:[], time: {name: 0, order: 0}}, next: {name: "Next", order:[], time: {name: 0, order: 0}}, 0: {order:[]}, length: 1}, time: 0}),
			// prefs: $.jStorage.get('prefs', {deleteWarnings: false, gpu: false, nextAmount: 'threeItems', over50: true, lang: 'english', bg: {color: '', size: 'tile'}, sync: {}}),
			// NB: Over 50 caps amount of tasks in List to 50 but causes drag and drop problems.
			// I CBF fixing it.
	
			save: function () {
				//Saves to localStorage
				// $.jStorage.set('tasks', server.tasks);
				// $.jStorage.set('lists', server.lists);
				// $.jStorage.set('queue', server.queue);
				// $.jStorage.set('prefs', server.prefs);
			},
	
			sync: {
	
				// Magical function that handles connect and emit
				run: function() {
	
					if(server.prefs.access) {
						server.sync.emit()
					} else {
						server.sync.connect(function() {
							server.sync.emit();
						});
					}
	
				},
				connect: function (callback) {
	
					console.log("Connecting to Nitro Sync server");
	
					if(server.prefs.sync.hasOwnProperty('access')) {
						$.ajax({
							type: "POST",
							url: 'http://localhost:3000/auth/',
							dataType: 'json',
							data: {access: server.prefs.sync.access, service: 'ubuntu'},
							success: function (data) {
								console.log(data);
								if(data == "success") {
									console.log("Nitro Sync server is ready");
									callback();
								} else if (data == "failed") {
									console.log("Could not connect to Dropbox");
								}
							}
						});
					} else {
						$.ajax({
							type: "POST",
							url: 'http://localhost:3000/auth/',
							dataType: 'json',
							data: {reqURL: 'true', service: 'ubuntu'},
							success: function (data) {
								console.log("Verifying dropbox");
								server.prefs.sync.token = data;
								// Display popup window
								var left = (screen.width/2)-(800/2),
									top = (screen.height/2)-(600/2),
									title = "Authorise Nitro",
									targetWin = window.open (data.authorize_url, title, 'toolbar=no, type=popup, status=no, width=800, height=600, top='+top+', left='+left);
								$.ajax({
									type: "POST",
									url: 'http://localhost:3000/auth/',
									dataType: 'json',
									data: {token: server.prefs.sync.token, service: 'ubuntu'},
									success: function (data) {
										console.log("Nitro Sync server is ready");
										server.prefs.sync.access = data;
										callback();
										// server.save();
									}
								});
							}
						});
					}
				},
	
				emit: function () {
					var client = {
						tasks: server.tasks,
						queue: server.queue,
						lists: server.lists
					};
	
					console.log(JSON.stringify(compress(client)));
	
					$.ajax({
						type: "POST",
						url: 'http://localhost:3000/sync/',
						dataType: 'json',
						data: {data: JSON.stringify(compress(client)), access: server.prefs.sync.access, service: 'ubuntu'},
						success: function (data) {
							if(data != 'failed') {
								data = decompress(data);
								console.log("Finished sync");
								server.tasks = data.tasks;
								server.queue = data.queue;
								server.lists = data.lists;
								// server.save();
								ui.sync.reload();
							} else {
								console.log("Sync failed. You probably need to delete server.prefs.sync.");
							}
						}
					});
	
				}
			}
		}
	};
	
	
	// Loop through each list
	for (var list in client.lists.items) {

		if (list != '0' && list !== 'length') {

			// Check if it is a new list
			if (client.lists.items[list].synced === false || client.lists.items[list].synced === 'false') {

				console.log("List '" + list + "' has never been synced before");

				client.lists.items[list].synced = true;

				// If a list with that id already exists on the server
				if (server.lists.items.hasOwnProperty(list)) {

					console.log("List '" + list + "' already exists on the server");

					// Change the list ID
					client.lists.items[server.lists.items.length] = clone(client.lists.items[list]);
					delete client.lists.items[list];

					console.log("List '" + list + "' has been moved to '" + server.lists.items.length + "'");

					list = server.lists.items.length;

				} else {
					console.log("List '" + list + "' does not exist on server. Adding to server.");
				}

				// If the list doesn't exist on the server, create it
				server.lists.items[server.lists.items.length] = {
					name: client.lists.items[list].name,
					order: [],
					time: client.lists.items[list].time,
					synced: true
				};

				// Update order
				server.lists.order.push(Number(list));
				server.lists.items.length++;

			} else if (server.lists.items.hasOwnProperty(list)) {

				console.log("List '" + list + "' exists on server.");

				for(var key in client.lists.items[list].time) {

					if (client.lists.items[list].time[key] > server.lists.items[list].time[key]) {

						console.log("The key '" + key + "' in list '" + list + "' has been modified.");

						console.log(color(JSON.stringify(client.lists.items[list][key]), 'red'))

						// If so, update list key and time
						server.lists.items[list][key] = client.lists.items[list][key];
						server.lists.items[list].time[key] = client.lists.items[list].time[key];

						console.log(color(JSON.stringify(server.lists.items[list][key]), 'red'))
					}
				}

			} else {
				console.log(color("ERROR: Client has a list that has been synced before but it doesn't exist on the server...", "red"));
			}
		}
	}

	// Loop through each task
	for(var task in client.tasks) {

		// Do not sync the tasks.length propery
		// This should only be modified by the server side cli.js
		if (task !== 'length') {

			/***** ADDING NEW TASKS TO THE SERVER *****/

			// If task has never been synced before
			if (client.tasks[task].synced === false || client.tasks[task].synced === 'false') {

				console.log("Task '" + task + "' has never been synced before");

				// Task is going to be added to the server so we delete the synced property
				client.tasks[task].synced = true;

				// If task already exists on the server (Don't be fooled, it's a different task...)
				if (server.tasks.hasOwnProperty(task)) {

					console.log("A task with the ID '" + task + "' already exists on the server");

					// Does not mess with ID's if it isn't going to change
					if (server.tasks.length !== Number(task)) {

						// Add task to task (ID + server.tasks.length)
						client.tasks[server.tasks.length] = clone(client.tasks[task]);
						delete client.tasks[task];

						console.log("Task '" + task + "' has been moved to task '" + server.tasks.length  + "'");

						task = server.tasks.length;

					}
				}

				// If task hasn't been deleted
				if (!client.tasks[task].hasOwnProperty('deleted')) {

					console.log("Task '" + task + "' is being added to the server.");

					// Add the task to the server
					cli.addTask("New Task", client.tasks[task].list);
					server.tasks[task] = clone(client.tasks[task]);

					// Calculate date
					cli.calc.date(task);

					// Calculate Today etc? - Do later
					cli.today(task).calculate();

					// Fix task length
					fixLength(server.tasks);

				// The task is new, but the client deleted it
				} else {

					console.log("Task '" + task + "' is new, but the client deleted it");

					// Add the task to the server, but don't touch lists and stuff
					server.tasks[task] = clone(client.tasks[task]);

				}

			/***** CLIENT DELETED TASK *****/

			// Task was deleted on computer but not on the server
			} else if (client.tasks[task].hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

				console.log("Task '" + task + "' was deleted on computer but not on the server");

				// We use this to check whether the task was modified AFTER it was deleted
				var deleteTask = true;

				// Loop through each attribute on server
				for(var key in server.tasks[task]) {

					// Check if server task was modified after task was deleted
					if (server.tasks[task].time[key] > client.tasks[task].deleted) {

						console.log("Task '" + task + "' was modified after task was deleted");

						// Since it has been modified after it was deleted, we don't delete the task
						deleteTask = false;

					}
				}

				// If there have been no modifications to the task after it has been deleted
				if (deleteTask) {

					// Delete the task
					cli.deleteTask(task);

					// Get the timestamp
					server.tasks[task] = clone(client.tasks[task]);

					// Update stuff
					// cli.calc.date(task);
					// cli.today(task).calculate();

				}

			/***** SERVER DELETED TASK *****/

			// Task is deleted on the server and the computer
			} else if (client.tasks[task].hasOwnProperty('deleted') && server.tasks[task].hasOwnProperty('deleted')){

				console.log("Task '" + task + "' is deleted on the server and the computer");

				// Use the latest time stamp
				if (client.tasks[task].deleted > server.tasks[task].deleted) {

					console.log("Task '" + task + "' is deleted, but has a newer timestamp");

					// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
					server.tasks[task].deleted = client.tasks[task].deleted;

				}

			/***** OLD TASK THAT HASN'T BEEN DELETED BUT POSSIBLY MODIFIED *****/

			} else {

				console.log("Task '" + task + "' exists on the server and hasn't been deleted");

				//Stores the Attrs we'll be needing later
				var changedAttrs = [];

				// Loop through each attribute on computer
				for(var key in client.tasks[task]) {

					//Don't loop through timestamps
					if (key !== 'time') {

						// Check if task was deleted on server or
						if (server.tasks[task].hasOwnProperty('deleted')) {

							console.log("Task '" + task + "' was deleted on the server");

							// Check if task was modified after it was deleted
							if (client.tasks[task].time[key] > server.tasks[task].deleted) {

								console.log("Task " + task + " was modified on the client after it was deleted on the server");

								// Update the server with the entire task (including attributes and timestamps)
								server.tasks[task] = client.tasks[task];

								//Breaks, we only need to do the thing once.
								break;
							}

						// Task has not been deleted
						} else {

							// If the attribute was updated after the server
							if (client.tasks[task].time[key] > server.tasks[task].time[key]) {

								console.log("Key '" + key + "'  in task " + task + " has been updated by the client");

								if (key !== 'list') {
									// Update the servers version
									server.tasks[task][key] = client.tasks[task][key];
								}
								
								// Update the timestamp
								server.tasks[task].time[key] = client.tasks[task].time[key];

								//Adds the changed Attr to the array
								changedAttrs.push(key);
							}
						}
					}
				}

				if (changedAttrs.length > 0) {
					if (changedAttrs.indexOf('logged') != -1) {
						// Logged
						console.log("Task " + task + " has been updated --> LOGGED");
						cli.logbook(task);
						cli.logbook(task);
					} else if (changedAttrs.indexOf('date') != -1 || changedAttrs.indexOf('showInToday') != -1) {
						// Date is changed
						console.log("Task " + task + " has been updated --> DATE");
						cli.calc.date(task);
						cli.today(task).calculate();
					} else if (changedAttrs.indexOf('today') != -1) {
						// Today
						console.log("Task " + task + " has been updated --> TODAY");
						cli.today(task).calculate();
					}

					if (changedAttrs.indexOf('list') != -1) {
						// List
						console.log("Task " + task + " has been updated --> LIST");
						cli.moveTask(task, client.tasks[task].list);
					}
				}
			}
		}
	}
	
	// Loop through each task
	for(var task in client.lists.scheduled) {
	
		// Do not sync the tasks.length propery
		// This should only be modified by the server side cli.js
		if (task !== 'length') {
	
			/***** ADDING NEW TASKS TO THE SERVER *****/
	
			// If task has never been synced before
			if (client.lists.scheduled[task].synced === false || client.lists.scheduled[task].synced === 'false') {
	
				console.log("Task '" + task + "' has never been synced before");
	
				// Task is going to be added to the server so we delete the synced property
				client.lists.scheduled[task].synced = true;
	
				// If task already exists on the server (Don't be fooled, it's a different task...)
				if (server.lists.scheduled.hasOwnProperty(task)) {
	
					console.log("A task with the ID '" + task + "' already exists on the server");
	
					// Does not mess with ID's if it isn't going to change
					if (server.lists.scheduled.length !== Number(task)) {
	
						// Add task to task (ID + server.lists.scheduled.length)
						client.lists.scheduled[server.lists.scheduled.length] = clone(client.lists.scheduled[task]);
						delete client.lists.scheduled[task];
	
						console.log("Task '" + task + "' has been moved to task '" + server.lists.scheduled.length  + "'");
	
						task = server.lists.scheduled.length;
	
					}
				}
	
				// If task hasn't been deleted
				if (!client.lists.scheduled[task].hasOwnProperty('deleted')) {
	
					console.log("Task '" + task + "' is being added to the server.");
	
					// Add the task to the server
					cli.scheduled.add("New Task", client.lists.scheduled[task].type);
					server.lists.scheduled[task] = clone(client.lists.scheduled[task]);
	
					// Fix task length
					fixLength(server.lists.scheduled);
	
				// The task is new, but the client deleted it
				} else {
	
					console.log("Task '" + task + "' is new, but the client deleted it");
	
					// Add the task to the server, but don't touch lists and stuff
					server.lists.scheduled[task] = clone(client.lists.scheduled[task]);
	
				}
	
			/***** CLIENT DELETED TASK *****/
	
			// Task was deleted on computer but not on the server
			} else if (client.lists.scheduled[task].hasOwnProperty('deleted') && !server.lists.scheduled[task].hasOwnProperty('deleted')) {
	
				console.log("Task '" + task + "' was deleted on computer but not on the server");
	
				// We use this to check whether the task was modified AFTER it was deleted
				var deleteTask = true;
	
				// Loop through each attribute on server
				for(var key in server.lists.scheduled[task]) {
	
					// Check if server task was modified after task was deleted
					if (server.lists.scheduled[task].time[key] > client.lists.scheduled[task].deleted) {
	
						console.log("Task '" + task + "' was modified after task was deleted");
	
						// Since it has been modified after it was deleted, we don't delete the task
						deleteTask = false;
	
					}
				}
	
				// If there have been no modifications to the task after it has been deleted
				if (deleteTask) {
	
					// Delete the task
					cli.deleteTask('s' + task);
	
					// Get the timestamp
					server.lists.scheduled[task] = clone(client.lists.scheduled[task]);
	
				}
	
			/***** SERVER DELETED TASK *****/
	
			// Task is deleted on the server and the computer
			} else if (client.lists.scheduled[task].hasOwnProperty('deleted') && server.lists.scheduled[task].hasOwnProperty('deleted')){
	
				console.log("Task '" + task + "' is deleted on the server and the computer");
	
				// Use the latest time stamp
				if (client.lists.scheduled[task].deleted > server.lists.scheduled[task].deleted) {
	
					console.log("Task '" + task + "' is deleted, but has a newer timestamp");
	
					// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
					server.lists.scheduled[task].deleted = client.lists.scheduled[task].deleted;
	
				}
	
			/***** OLD TASK THAT HASN'T BEEN DELETED BUT POSSIBLY MODIFIED *****/
	
			} else {
	
				console.log("Task '" + task + "' exists on the server and hasn't been deleted");
	
				// Loop through each attribute on computer
				for(var key in client.lists.scheduled[task]) {
	
					//Don't loop through timestamps
					if (key !== 'time') {
	
						// Check if task was deleted on server or
						if (server.lists.scheduled[task].hasOwnProperty('deleted')) {
	
							console.log("Task '" + task + "' was deleted on the server");
	
							// Check if task was modified after it was deleted
							if (client.lists.scheduled[task].time[key] > server.lists.scheduled[task].deleted) {
	
								console.log("Task " + task + " was modified on the client after it was deleted on the server");
	
								// Update the server with the entire task (including attributes and timestamps)
								server.lists.scheduled[task] = client.lists.scheduled[task];
	
								//Breaks, we only need to do the thing once.
								break;
							}
	
						// Task has not been deleted
						} else {
	
							// If the attribute was updated after the server
							if (client.lists.scheduled[task].time[key] > server.lists.scheduled[task].time[key]) {
	
								console.log("Key '" + key + "'  in task " + task + " has been updated by the client");
	
								if (key !== 'list') {
									// Update the servers version
									server.lists.scheduled[task][key] = client.lists.scheduled[task][key];
								}
								
								// Update the timestamp
								server.lists.scheduled[task].time[key] = client.lists.scheduled[task].time[key];

							}
						}
					}
				}
			}
		}
	}

	// Fix task length
	fixLength(server.tasks)

	// Get rid of duplicates
	for(var list in server.lists.items) {
		if (list != 'length') server.lists.items[list].order = deDupe(server.lists.items[list].order);
	}

	callback(server);
}

// Clone an object or array
function clone(input) {
	return JSON.parse(JSON.stringify(input));
}

// Fix the length of an object
function fixLength(obj) {
	// Update length
	[obj].length = 0;
	for (i in [obj]) {
		if ([obj].hasOwnProperty(i) && i !== 'length') {
			[obj].length++;
		}
	}
}

// Remove duplicates from an array
function deDupe(arr) {
	var r = [];
	o:for(var i = 0, n = arr.length; i < n; i++) {
		for(var x = 0, y = r.length; x < y; x++) {
			if (r[x] == arr[i]) {
				continue o;
			}
		}
		r[r.length] = Number(arr[i]);
	}
	return r;
}

// My super awesome function that converts a string to a number
// "421".toNum()  -> 421
// "word".toNum() -> "word"
String.prototype.toNum = function () {
	var x = parseInt(this, 10);
	if (x > -100) {
		return x;
	} else {
		return this.toString();
	}
};

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
		deleted:     'u'
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
		u: 'deleted'
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

// Because typeof is useless here
function isArray(obj) {
    return obj.constructor == Array;
}
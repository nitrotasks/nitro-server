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

var settings = {
	version: "1.4",
	filename: 'nitro_data.json',
	url: 'http://localhost:3000',
	timeout: 180 // How long the server will wait for the user to authenticate Nitro.
}

// Node Packages
var express = require('express'),
	app = express.createServer(),
	dbox = require("dbox").app({ "app_key": "da4u54t1irdahco", "app_secret": "3ydqe041ogqe1zq" }),
	OAuth = require("oauth").OAuth;

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

// Dropbox callback
app.get('/dropbox', function (req, res) {
	res.send('<meta HTTP-EQUIV="REFRESH" content="0; url=http://localhost:3000/success/">');
	var uid = req.query.uid,
		token = req.query.oauth_token;
		if(users.dropbox.hasOwnProperty(token)) {
			users.dropbox[token].uid = uid;
		}
});

// Ubuntu callback for oauth verifier
app.get('/ubuntu-one/', function (req, res) {
	res.send('<meta HTTP-EQUIV="REFRESH" content="0; url=http://localhost:3000/success/">');
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
			merge(server, recievedData, function (server) {
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
	server.version = settings.version
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

// Create server
var emptyServer = {
	tasks: {
		length: 0
	},
	lists: {
		order: [],
		items: {
			today: {
				order: [],
				time: {
					order: 0
				}
			},
			next: {
				order: [],
				time: {
					order: 0
				}
			},
			logbook:{
				order:[],
				time:{
					order:0
				}
			},
			scheduled:{
				order:[],
				time:{
					order:0
				}
			},
			length: 0
		},
		time: 0
	}
};

function merge(server, client, callback) {

	console.log(JSON.stringify(client, null, 2));
	console.log("=============================");
	console.log(JSON.stringify(server, null, 2));

	var core = {
		task: function(id) {
			return {
				add: function(name, list) {
					//ID of task
					var taskId = server.tasks.length;
					server.tasks.length++;

					//Saves
					server.tasks[taskId] = {
						content: name,
						priority: 'none',
						date: '',
						notes: '',
						list: list,
						logged: false,
						time: {
							content: 0,
							priority: 0,
							date: 0,
							notes: 0,
							list: 0,
							logged: 0
						},
						synced: false
					};

					//Pushes to array
					server.lists.items[list].order.unshift(taskId);
					// server.save();
					console.log('Adding Task: ' + name + ' into list: ' + list);

					return taskId;
				},

				/* Move a task somewhere.
				e.g: core.task(0).move('next');

				To delete something, move to 'trash' */

				move: function(list, time) {

					Array.prototype.remove= function(){
						var what, a= arguments, L= a.length, ax;
						while(L && this.length){
							what= a[--L];
							while((ax= this.indexOf(what))!= -1){
								this.splice(ax, 1);
							}
						}
						return this;
					}

					//Fix for scheduled list
					if (server.tasks[id].type) {
						var old = 'scheduled';
					} else {
						var old = server.tasks[id].list;
					}

					// Dropping a task onto the Logbook completes it
					if(list == 'logbook' && !server.tasks[id].logged) {
						server.tasks[id].logged = 1;
						console.log('Logged ' + id);
						// server.save(['tasks', id, 'logged']);
					}

					// Taking a task out of the logbook
					if(server.tasks[id].list == list && server.tasks[id].logged && list != 'logbook') {
						console.log("Unlogging task")
						server.tasks[id].logged = false;
						// server.save(['tasks', id, 'logged']);
					} else if (list === 'trash') {
						//Remove from list
						server.lists.items[old].order.remove(id);
						// delete server.tasks[id];
						server.tasks[id] = {deleted: 1};
						console.log('Deleted: ' + id);
						// Saves - but doesn't mess with timestamps
						// server.save();
					} else {
						//Remove from list
						server.lists.items[old].order.remove(id);
						//Move to other list
						server.lists.items[list].order.unshift(id);
						server.tasks[id].list = list;
						console.log('Moved: ' + id + ' to ' + list);
						//Saves
						// server.save([['tasks', id, 'list'],['lists', list, 'order'],['lists', old, 'order']]);
					}
				}			
			}
		},
		list: function(id) {
			return {
				delete: function(time) {

					//Deletes tasks in a list
					for (var i = server.lists.items[id].order.length - 1; i >= 0; i--) {
						core.task(server.lists.items[id].order[i]).move('trash');
					}

					//Remove from List order
					var index = server.lists.order.indexOf(id);
					if(index > -1) {
						server.lists.order.splice(index, 1);
					}

					console.log(JSON.stringify(server.lists.order))

					//Deletes List
					//server.lists.items[id] = {deleted: core.timestamp()};
					server.lists.items[id] = {deleted: time};
					// server.save();
				}
			}
		}
	}

	// MASSIVE TRY/CATCH FOR ERRORS (TEMPORARY UNTIL WE GET SOMETING ELSE SORTED OUT)
	// try {	

		// Loop through each list
		for (var list in client.lists.items) {

			list = list.toNum();

			if (list !== 'length') {

				console.log(list);

				// Check if it is a new list
				if (client.lists.items[list].synced === false || client.lists.items[list].synced === 'false') {

					console.log("List '" + list + "' has never been synced before");

					// List is now synced so set it to true
					client.lists.items[list].synced = true;

					// If a list with that ID already exists on the server
					if (server.lists.items.hasOwnProperty(list)) {

						console.log("List '" + list + "' already exists on the server");

						// Change the list ID
						var newID = server.lists.items.length;
						client.lists.items[newID] = clone(client.lists.items[list]);

						for(var task = 0; task < client.lists.items[list].order.length; task++) {

							console.log("Task in list: " + task);

							task = client.lists.items[list].order[task];

							client.tasks[task].list = newID;

							// Temporary fix - not the best way to do it.
							client.tasks[task].time.list = Date.now();
						}

						delete client.lists.items[list];

						console.log("List '" + list + "' has been moved to '" + server.lists.items.length + "'");

						list = server.lists.items.length;

					} else {
						console.log("List '" + list + "' does not exist on server. Adding to server as: " + server.lists.items.length);

						if(list != server.lists.items.length) {
							for(var task in client.lists.items[list].order) {

								task = client.lists.items[list].order[task];

								client.tasks[task].list = server.lists.items.length;

								// Temporary fix - not the best way to do it.
								client.tasks[task].time.list = Date.now();
							}
						}
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

				/***** LIST IS DELETED ON THE CLIENT BUT DOESN'T EXIST ON THE SERVER *****/
				} else if (client.lists.items[list].hasOwnProperty('deleted') && !server.lists.items.hasOwnProperty(list)) {

					console.log("LIST " + list + " IS DELETED ON THE CLIENT BUT DOESN'T EXIST ON THE SERVER")

					// Copy the deleted timestamp over
					server.lists.items[list] = {deleted: client.lists.items[list].deleted}; 

				/***** LIST IS DELETED ON THE CLIENT AND BUT NOT ON THE SERVER *****/

				 } else if (client.lists.items[list].hasOwnProperty('deleted') && !server.lists.items[list].hasOwnProperty('deleted')) {

					 console.log("LIST " + list + " IS DELETED ON THE CLIENT AND BUT NOT ON THE SERVER")

					var deleteList = true;

					// Check timestamps on client and server
					for(var key in server.lists.items[list].time) {

						// If server has been modified after client was deleted, don't delete the list.
						if(server.lists.items[list].time[key] > client.lists.items[list].deleted) {

							deleteList = false;

						}
					}

					// Delete the list
					if(deleteList) {

						core.list(list).delete(client.lists.items[list].deleted);

					}


				/***** LIST IS DELETED ON THE SERVER AND ON THE COMPUTER *****/

				} else if (server.lists.items[list].hasOwnProperty('deleted') && client.lists.items[list].hasOwnProperty('deleted')) {

					console.log("List '" + list + "' is deleted on the server and the computer");

					// Use the latest time stamp
					if (client.lists.items[list].deleted > server.lists.items[list].deleted) {

						console.log("List '" + list + "' is deleted, but has a newer timestamp");

						// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
						server.lists.items[list].deleted = client.lists.items[list].deleted;

					}



				/***** LIST IS DELETED ON THE SERVER AND BUT NOT ON THE COMPUTER *****/

				} else if (server.lists.items[list].hasOwnProperty('deleted') && client.lists.items.hasOwnProperty(list)) {

					console.log("LIST " + list + " IS DELETED ON THE SERVER AND BUT NOT ON THE COMPUTER")

					var keepList = true;

					// Check timestamps on client and server
					for(var key in client.lists.items[list].time) {

						// If the task on the client has been modified after task on the server was deleted, keep the list.
						if(client.lists.items[list].time[key] > server.lists.deleted[list]) {

							keepList = false;

						}
					}

					// Keep the list
					if(keepList) {

						server.lists.items[list] = clone(client.lists.items[list]);

					}

				} else if (server.lists.items.hasOwnProperty(list)) {

					console.log("List '" + list + "' exists on server.");

					for(var key in client.lists.items[list].time) {

						if(key != 'order') {

							if (client.lists.items[list].time[key] > server.lists.items[list].time[key]) {

								console.log("The key '" + key + "' in list '" + list + "' has been modified.");

								console.log(JSON.stringify(client.lists.items[list][key]))

								// If so, update list key and time
								server.lists.items[list][key] = client.lists.items[list][key];
								server.lists.items[list].time[key] = client.lists.items[list].time[key];

							}
						}
					}
				}
			}
		}

		// Loop through each task
		for(var task in client.tasks) {

			task = task.toNum();

			// Do not sync the tasks.length propery
			// This should only be modified by the server side core.js
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
						core.task().add("New Task", client.tasks[task].list);
						server.tasks[task] = clone(client.tasks[task]);

						// Fix task length
						fixLength(server.tasks);

					// The task is new, but the client deleted it
					} else {

						console.log("Task '" + task + "' is new, but the client deleted it");

						// Add the task to the server, but don't touch lists and stuff
						server.tasks[task] = clone(client.tasks[task]);

					}


				/***** TASK DOESN'T EXIST ON SERVER FOR SOME REASON -- BUG *****/
				} else if (!server.tasks.hasOwnProperty(task)) {

					console.log("Task " + task + " doesn't exist on server. It should, but it doesn't.");

					if(client.tasks[task].hasOwnProperty('deleted')) {

						console.log("Task " + task + " was deleted before it was sunk");

						server.tasks[task] = {deleted: client.tasks[task].deleted};
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
						core.task(task).move('trash', client.tasks[task].deleted);

						// Get the timestamp
						server.tasks[task] = clone(client.tasks[task]);

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
						if (changedAttrs.indexOf('date') != -1 || changedAttrs.indexOf('showInToday') != -1) {
							// Date is changed
							console.log("Task " + task + " has been updated --> DATE");
							//core.calc.date(task);
							//core.today(task).calculate();
						} else if (changedAttrs.indexOf('today') != -1) {
							// Today
							console.log("Task " + task + " has been updated --> TODAY");
							//core.today(task).calculate();
						}

						if (changedAttrs.indexOf('list') != -1) {
							// List
							console.log("Task " + task + " has been updated --> LIST");
							core.task(task).move(client.tasks[task].list);
							console.log(server.lists.items[client.tasks[task].list].order)
						}
					}
				}
			}
		}

		// Loop through each task
		for(var task in client.lists.scheduled) {

			// Do not sync the tasks.length propery
			// This should only be modified by the server side core.js
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
						core.scheduled.add("New Task", client.lists.scheduled[task].type);
						server.lists.scheduled[task] = clone(client.lists.scheduled[task]);

						// Fix task length
						fixLength(server.lists.scheduled);

					// The task is new, but the client deleted it
					} else {

						console.log("Task '" + task + "' is new, but the client deleted it");

						// Add the task to the server, but don't touch lists and stuff
						server.lists.scheduled[task] = clone(client.lists.scheduled[task]);

					}

				/***** TASK DOESN'T EXIST ON SERVER FOR SOME REASON -- BUG *****/
				} else if (!server.tasks.hasOwnProperty(task)) {

					console.log("Task doesn't exist on server. It should, but it doesn't.");

					// Better just copy the task onto the server...
					server.lists.scheduled[task] = clone(client.lists.scheduled[task]);

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
						core.deleteTask('s' + task);

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

		var ArrayDiff = function(a,b) {
			return a.filter(function(i) {return !(b.indexOf(i) > -1);});
		}

		// Merge list order...
		var mergeOrder = function(c, s) {
			// Find diff
			var sD = ArrayDiff(s.order, c.order);
			var cD = ArrayDiff(c.order, s.order);

			// Check if only order has been changed
			var sameKeys = !sD.length && !cD.length;

			// Only order has been changed
			if(sameKeys) {

				// Use newer timestamp
				if(c.time > s.time) {
					console.log("List order: Same keys so going with latest version - Client")
					return [c.order, c.time];
				} else {
					console.log("List order: Same keys so going with latest version - Server")
					return [s.order, s.time];
				}

			} else {

				// Crazy merging code
				console.log("List order: Using crazy merging code")

				// Remove all keys that aren't in the server
				c.order = ArrayDiff(c.order, cD);

				for(var i = 0; i < sD.length; i++) {
					// Get the index of each key in the ServerDiff
					var index = s.order.indexOf(sD[i]);
					// Inject the key into the client
					c.order.splice(index, 0, sD[i]);
				}

				return [c.order, c.time];
			}
		};

		// Merge List Order

		var c = {
			order: client.lists.order,
			time: client.lists.time
		},
		s = {
			order: server.lists.order,
			time: server.lists.time
		}

		var mergedListOrder = mergeOrder(c, s);
		server.lists.order = mergedListOrder[0];
		server.lists.time = mergedListOrder[1];

		// Merge Task Order

		// Loop through each list (again)
		for (var list in client.lists.items) {
			list = list.toNum();
			if (list !== 'length' && !server.lists.items[list].hasOwnProperty('deleted')) {

				var c = {
					order: client.lists.items[list].order,
					time: client.lists.items[list].time.order
				},
				s = {
					order: server.lists.items[list].order,
					time: server.lists.items[list].time.order
				}

				var mergedListOrder = mergeOrder(c, s);

				console.log(list)
				console.log(JSON.stringify(c));
				console.log(JSON.stringify(s));

				server.lists.items[list].order = mergedListOrder[0];
				server.lists.items[list].time.order = mergedListOrder[1];

			}
		}


		callback(server);

	// } catch (e) {

	// 	console.log(e);

	// }
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
		deleted:     'u',
		logbook: 	 'v',
		scheduled: 	 'w',
		version: 	 'x'
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
		x: 'version'
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
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

console.info('Nitro Sync 1.2\nCopyright (C) 2012 Caffeinated Code\nBy George Czabania & Jono Cooper');

// Node Packages
var color = require('./lib/ansi-color').set,
	express = require('express'),
	app = express.createServer(),
	dbox = require("dbox").app({ "app_key": "da4u54t1irdahco", "app_secret": "3ydqe041ogqe1zq" }),
	client = {},
	server = {};

// Enable cross browser ajax
// app.enable("jsonp callback");
app.use(express.bodyParser());

// Handles HTTP Requests
app.get('/', function (req, res) {
    res.send('This is the Nitro Sync API. Hello.');
});

// Initial Auth
app.post('/auth/', function (req, res) {

	console.log(color("** Starting Auth **", "blue"));

	// If the client has never been connected before
	if (req.param('reqURL', null)) {

		// Request a token from dropbox
		dbox.request_token(function (status, request_token) {
			console.log(color("Sending authorize_url", "blue"));

			// Send it to the client
			res.json(request_token);
		});

	// Client has a token but not oauth
	} else if (req.param('token', null)) {

		var count = 0;

		function checkServer () {
			console.log(color('Connecting to dropbox', "blue"));

			// Check token 
			dbox.access_token(req.param('token', null), function (status, access_token) {

				// Token is good :D
				if (status == 200) {
					console.log(color('Attempt '+count+' - Connected!', "yellow"));

					// Create client
					client = dbox.createClient(access_token);

					// Get server.json
					getServer();

					// Send access token to client so they can use it again
					client.account(function (status, reply) {
						res.json(access_token);
					});

				// Nitro hasn't been allowed yet :(
				} else {
					console.log(color('Attempt '+count+' - Failed!', "red"));
					count++;

					// Try again in a second
					setTimeout(checkServer, 1000);
				}
			});
		}

		checkServer();

	// Server has been authorised before
	} else if (req.param('access', null)) {

		console.log(color("Using client stored key", "blue"));

		// Create client
		client = dbox.createClient(req.param('access', null));

		// Check to see if it worked
		client.account(function (status, reply) {
			if (status == 200) {
				console.log(color("Connected!", "yellow"));
				res.json("success");
			} else {
				console.log(color("Could not connect :(", "red"));
				res.json("failed");
			}
		});
	}
});

// Timestamps Only
app.post('/update/', function(req, res){
	res.send('token: ' + req.query["token"] + '<br>timestamp: ' + req.query["timestamp"]);
});

// Actual Sync
app.post('/sync/', function(req, res){

	req.param('data').tasks = JSON.parse(deflate(JSON.stringify(req.param('data').tasks)));
	// Merge data
	merge(req.param('data', null), function() {
		// Send data back to client
		console.log("Merge complete. Updating client.")
		res.json(server);
		saveServer();
	});
});

app.listen(3000);

function getServer() {
	console.log(color("Getting server.json from dropbox", 'blue'));
	client.get("server.json", function (status, reply) {
		reply = JSON.parse(reply.toString());
		// Check if file exists
		if(reply.hasOwnProperty('error')) {
			console.log(color("Server.json doesn't exist on the clients dropbox :(", 'red'));
			console.log(color("So let's make one :D", 'blue'));
			server = clone(emptyServer);
			saveServer();
		} else {
			console.log(color("Got the server!", 'yellow'));
			server = clone(reply);
		}
	});
}

function saveServer() {
	console.log(color("Saving to server (starting)", 'blue'));
	var output = JSON.stringify(server, null, 4);
	client.put("server.json", output, function () {
		console.log(color("Saving to server (complete!)", 'yellow'));
	});
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
			someday: {
				name: "Someday",
				order: [],
				time: {
					name: 0,
					order: 0
				}
			},
			length: 1
		},
		time: 0
	},
	queue: {}
}

function clone(input) {
	return JSON.parse(JSON.stringify(input));
}

function fixLength(obj) {
	// Update length
	[obj].length = 0;
	for (i in [obj]) {
		if ([obj].hasOwnProperty(i) && i != 'length') {
			[obj].length++;
		}
	}
}

function merge(client, callback) {

	console.log(color(JSON.stringify(client), 'green'));

	// Loop through each list
	for (var list in client.lists.items) {

		if(list != '0' && list != 'length') {

			// Check if it is a new list
			if (client.lists.items[list].synced === false || client.lists.items[list].synced == 'false') {

				console.log(color("170", "blue"), ": List '" + list + "' has never been synced before");

				client.lists.items[list].synced = true;

				// If a list with that id already exists on the server
				if (server.lists.items.hasOwnProperty(list)) {

					console.log(color("177", "blue"), ": List '" + list + "' already exists on the server");

					// Change the list ID
					client.lists.items[server.lists.items.length] = clone(client.lists.items[list]);
					delete client.lists.items[list];

					console.log(color("177", "blue"), ": List '" + list + "' has been moved to '" + server.lists.items.length + "'");

					list = server.lists.items.length;

				} else {
					console.log(color("188", "blue"), ": List '" + list + "' does not exist on server. Adding to server.")
				}

				// If the list doesn't exist on the server, create it
				server.lists.items[server.lists.items.length] = {
					name: client.lists.items[list].name,
					order: [],
					time: client.lists.items[list].time,
					synced: true
				}

				// Update order
				server.lists.order.push(Number(list));
				server.lists.items.length++;

			} else {

				console.log(color("204", "blue"), ": List '" + list + "' exists on server.")

				for(var key in client.lists.items[list].time) {

					if(client.lists.items[list].time[key] > server.lists.items[list].time[key]) {

						console.log(color("164", "blue"), ": The key '" + key + "' in list '" + list + "' has been modified.")

						// If so, update list key and time
						server.lists.items[list][key] = client.lists.items[list][key];
						server.lists.items[list].time[key] = client.lists.items[list].time[key];
					}
				}
			}
		}	
	}

	// Loop through each task
	for(var task in client.tasks) {

		// Do not sync the tasks.length propery
		// This should only be modified by the server side cli.js
		if(task != 'length') {

			/***** ADDING NEW TASKS TO THE SERVER *****/

			// If task has never been synced before
			if(client.tasks[task].synced === false || client.tasks[task].synced === 'false') {

				console.log(color("209", "blue"), ": Task '" + task + "' has never been synced before");

				// Task is going to be added to the server so we delete the synced property
				client.tasks[task].synced = true;

				// If task already exists on the server (Don't be fooled, it's a different task...)
				if(server.tasks.hasOwnProperty(task)) {

					console.log(color("217", "blue"), ": A task with the ID '" + task + "' already exists on the server");

					// Does not mess with ID's if it isn't going to change
					if(server.tasks.length != parseInt(task)) {

						// Add task to task (ID + server.tasks.length)
						client.tasks[server.tasks.length] = clone(client.tasks[task]);
						delete client.tasks[task];

						console.log(color("226", "blue"), ": Task '" + task + "' has been moved to task '" + server.tasks.length  + "'");

						task = server.tasks.length;

					}
				} 

				// If task hasn't been deleted
				if(!client.tasks[task].hasOwnProperty('deleted')) {

					console.log(color("237", "blue"), ": Task '" + task + "' is being added to the server.")

					// Add the task to the server
					cli.addTask("New Task", client.tasks[task].list);
					server.tasks[task] = clone(client.tasks[task]);

					// Calculate date
					cli.calc.date(task);

					// Calculate Today etc? - Do later
					cli.today(task).calculate();

					// Fix task length
					fixLength(server.tasks)

				// The task is new, but the client deleted it
				} else {

					console.log(color("252", "blue"), ": Task '" + task + "' is new, but the client deleted it")

					// Add the task to the server, but don't touch lists and stuff
					server.tasks[task] = clone(client.tasks[task]);

				}

			/***** CLIENT DELETED TASK *****/

			// Task was deleted on computer but not on the server
			} else if(client.tasks[task].hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

				console.log(color("266", "blue"), ": Task '" + task + "' was deleted on computer but not on the server")

				// We use this to check whether the task was modified AFTER it was deleted
				var deleteTask = true;

				// Loop through each attribute on server
				for(var key in server.tasks[task]) {

					// Check if server task was modified after task was deleted
					if(server.tasks[task].time[key] > client.tasks[task].deleted) {

						console.log(color("277", "blue"), ": Task '" + task + "' was modified after task was deleted")

						// Since it has been modified after it was deleted, we don't delete the task
						deleteTask = false;

					}
				}

				// If there have been no modifications to the task after it has been deleted
				if(deleteTask) {

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
			} else if(client.tasks[task].hasOwnProperty('deleted') && server.tasks[task].hasOwnProperty('deleted')){

				console.log(color("305", "blue"), ": Task '" + task + "' is deleted on the server and the computer")

				// Use the latest time stamp
				if(client.tasks[task].deleted > server.tasks[task].deleted) {

					console.log(color("310", "blue"), ": Task '" + task + "' is deleted, but has a newer timestamp")

					// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
					server.tasks[task].deleted = client.tasks[task].deleted;

				}

			/***** OLD TASK THAT HASN'T BEEN DELETED BUT POSSIBLY MODIFIED *****/

			} else {

				console.log(color("321", "blue"), ": Task '" + task + "' exists on the server and hasn't been deleted")

				//Stores the Attrs we'll be needing later
				var changedAttrs = [];

				// Loop through each attribute on computer
				for(var key in client.tasks[task]) {

					//Don't loop through timestamps
					if (key != 'time') {

						// Check if task was deleted on server or 
						 if (server.tasks[task].hasOwnProperty('deleted')) {

						 	console.log(color("335", "blue"), ": Task '" + task + "' was deleted on the server");

							// Check if task was modified after it was deleted
							if(client.tasks[task].time[key] > server.tasks[task].deleted) {

								console.log(color("340", "blue"), ": Task " + task + " was modified on the client after it was deleted on the server");

								// Update the server with the entire task (including attributes and timestamps)
								server.tasks[task] = client.tasks[task];

								//Breaks, we only need to do the thing once.
								break;
							}

						// Task has not been deleted
						} else {

							// If the attribute was updated after the server
							if(client.tasks[task].time[key] > server.tasks[task].time[key]) {

								console.log(color("355", "blue"), ": Key '" + key + "'  in task " + task + " has been updated by the client");

								if (key != 'list') {
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
					if(changedAttrs.indexOf('logged') != -1) {
						// Logged
						console.log(color("375", "blue"), ": Task " + task + " has been updated --> LOGGED");
						cli.logbook(task)
						cli.logbook(task)
					} else if(changedAttrs.indexOf('date') != -1 || changedAttrs.indexOf('showInToday') != -1) {
						// Date is changed
						console.log(color("380", "blue"), ": Task " + task + " has been updated --> DATE");
						cli.calc.date(task);
						cli.today(task).calculate();
					} else if(changedAttrs.indexOf('today') != -1) {
						// Today
						console.log(color("385", "blue"), ": Task " + task + " has been updated --> TODAY");
						cli.today(task).calculate();
					}

					if(changedAttrs.indexOf('list') != -1) {
						// List
						console.log(color("391", "blue"), ": Task " + task + " has been updated --> LIST");
						cli.moveTask(task, client.tasks[task].list)
					}
				}
			}
		}
	}

	// Fix task length
	fixLength(server.tasks)

	// Get rid of duplicates
	for(var list in server.lists.items) {
		if(list != 'length') server.lists.items[list].order = deDupe(server.lists.items[list].order);
	}

	callback();
}

var cli = {
	timestamp: {
		update: function (id, key) {
			return {
				task: function () {
					// server.tasks[id].time[key] = Date.now();
					// cli.timestamp.sync();
				},
				list: function () {
					if (id !== 0) {
						// server.lists.items[id].time[key] = Date.now();
						// cli.timestamp.sync();
					}
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
				if (id !== 'length') {

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
					if (server.tasks[id].hasOwnProperty('synced')) {
						console.log("Upgrading task: '" + id + "' to Nitro 1.2 (sync)");
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

			// Check preferences exist. If not, set to default
			server.lists.time     = server.prefs.time     || 0;
			server.prefs.sync     = server.prefs.sync     || 'manual';
			server.prefs.lang     = server.prefs.lang     || 'english';
			server.prefs.bg       = server.prefs.bg       || {};
			server.prefs.bg.color = server.prefs.bg.color || '';
			server.prefs.bg.size  = server.prefs.bg.size  || 'zoom';

			// Save
			// server.save();

			if (passCheck) {
				// Database is up to date
				console.log("Database is up to date")
			} else {
				// Database was old
				console.log("Database was old")
				console.log("Regex all the things!")

				//Regexes for funny chars
				localStorage.jStorage = localStorage.jStorage.replace(/\\\\/g, "&#92;").replace(/\|/g, "&#124").replace(/\\"/g, "&#34;").replace(/\'/g, "&#39;");

				//Reloads jStorage
				// $.jStorage.reInit()
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
		cli.timestamp.update(list, 'order').list();

		//Saves to disk
		// server.save();

		//Returns something
		console.log("Created Task: '" + name + "' with id: " + id + " in list: " + list);

	},
	deleteTask: function (id) {
		var task = cli.taskData(id).display();

		// Timestamp (list order)
		cli.timestamp.update(task.list, 'order').list();

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
	},
	populate: function (type, query) {
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
								var data = cli.taskData(t).display();
								//remove today & date data
								data.date = '';
								data.today = 'false';
								cli.taskData(t).edit(data);

								logbook.push(t);
							}
						}
					}

					return logbook;

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

				// Search loop
				for (var t = 0; t < server.tasks.length; t++) {

					// If task exists
					if (server.tasks[t]) {

						// Exclude logged tasks
						if (!server.tasks[t].logged) {

							var pass1 = [],
								pass2  = true;

							// Loop through each word in the query
							for (var q = 0; q < query.length; q++) {

								// Create new search
								search = new RegExp(query[q], 'i');

								// Search
								if (search.test(server.tasks[t].content + server.tasks[t].notes)) {
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
								results.push(t);
							}
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
		cli.timestamp.update(id, 'list').task();
		cli.timestamp.update(task.list, 'order').list();
		cli.timestamp.update(list, 'order').list();

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
				cli.timestamp.update(id, 'showInToday').task();
				cli.timestamp.update(id, 'list').task();

				// Update timestamp
				cli.timestamp.update(id, 'today').task();

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
		cli.timestamp.update(id, 'logged').task();

		cli.taskData(id).edit(task);
		server.lists.items = lists;
		// server.save();
	},
	priority: function (id) {
		return {
			get: function () {
				var priority = server.tasks[id].priority;
				return priority;
			},
			set: function () {
				var priority = server.tasks[id].priority;
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

				cli.timestamp.update(id, 'priority').task();

				server.tasks[id].priority = priority;
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
					if(typeof obj[value] === 'string') {
						obj[i] = cli.escape(value);
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
				cli.timestamp.update(id, 'name').list();

				//Saves to localStorage
				// server.save();

				//Returns something
				console.log("Renamed List: " + id + " to: '" + name + "'");
			},
			remove: function () {
				//Deletes data in list
				for (var i=0; i<server.lists.items[id].order.length; i++) {
					cli.today(server.lists.items[id].order[i]).remove();
					delete server.tasks[server.lists.items[id].order[i]];
				}

				//Deletes actual list
				delete server.lists.items[id];
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
				cli.timestamp.update(id, 'order').list();
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

			console.log(color("Runing cli.calc.removeFromList", "red"), JSON.stringify(lists));

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
					if (difference < 0) {
						// Overdue
						difference = Math.abs(difference);
						if (difference !== 1) {
							return [$.i18n._('daysOverdue', [difference]), 'overdue'];
						} else {
							return [$.i18n._('dayOverdue'), 'overdue'];
						}
					} else if (difference === 0) {
						// Due
						return ["due today", 'due'];
					} else if (difference < 15) {
						// Due in the next 15 days
						if (difference !== 1) {
							return [$.i18n._('daysLeft', [difference]), ''];
						} else {
							return [$.i18n._('dayLeft'), ''];
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

	storage: {
		//Object where data is stored
		// tasks: $.jStorage.get('tasks', {length: 0}),
		// queue: $.jStorage.get('queue', {}),
		// lists: $.jStorage.get('lists', {order: [], items:{today: {name: "Today", order:[], time: {name: 0, order: 0}}, next: {name: "Next", order:[], time: {name: 0, order: 0}}, someday: {name: "Someday", order:[], time: {name: 0, order: 0}}, 0: {order:[]}, length: 1}, time: 0}),
		// prefs: $.jStorage.get('prefs', {deleteWarnings: false, gpu: false, nextAmount: 'threeItems', over50: true, lang: 'english', bg: {color: '', size: 'zoom'}, sync: 'manual'}),
		// NB: Over 50 caps amount of tasks in List to 50 but causes drag and drop problems.
		// I CBF fixing it.

		save: function () {
			//Saves to localStorage
			// $.jStorage.set('tasks', server.tasks);
			// $.jStorage.set('lists', server.lists);
			// $.jStorage.set('queue', server.queue);
			// $.jStorage.set('prefs', server.prefs);
		},

		sync: function () {

			console.log("Running sync");

			// Upload to server
			// var socket = io.connect('http://hollow-wind-1576.herokuapp.com/');
			var socket = io.connect('http://localhost:8080/');
			var client = {
				tasks: server.tasks,
				queue: server.queue,
				lists: server.lists
			};
			/*socket.on('token', function (data) {
				window.open(data);
				if (verify()) {
					socket.emit('allowed', '');
				}
			});
			function verify() {
				if (confirm("Did you allow Nitro?")) {
					return true;
				} else {
					verify();
				}
			}*/
			console.log(client);
			socket.emit('upload', client);

			// Get from server
			socket.on('download', function (data) {
				console.log("Finished sync");
				server.tasks = data.tasks;
				server.queue = data.queue;
				server.lists = data.lists;
				// server.save();
				ui.sync.reload();
			});
		}
	}
};

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
	if(x > -100) {
		return x;
	} else {
		return this.toString();
	}
}

//Compresses & Deflates data
function compress(str) {
	var final = str
		.replace(/\"content\"/g, "\"a\"")
		.replace(/\"priority\"/g, "\"b\"")
		.replace(/\"date\"/g, "\"c\"")
		.replace(/\"notes\"/g, "\"d\"")
		.replace(/\"today\"/g, "\"e\"")
		.replace(/\"showInToday\"/g, "\"f\"")
		.replace(/\"list\"/g, "\"g\"")
		.replace(/\"logged\"/g, "\"h\"")
		.replace(/\"time\"/g, "\"i\"")
		.replace(/\"synced\"/g, "\"j\"")

	return final;
}

function deflate(str) {
	var final = str
		.replace(/\"a\"/g, "\"content\"")
		.replace(/\"b\"/g, "\"priority\"")
		.replace(/\"c\"/g, "\"date\"")
		.replace(/\"d\"/g, "\"notes\"")
		.replace(/\"e\"/g, "\"today\"")
		.replace(/\"f\"/g, "\"showInToday\"")
		.replace(/\"g\"/g, "\"list\"")
		.replace(/\"h\"/g, "\"logged\"")
		.replace(/\"i\"/g, "\"time\"")
		.replace(/\"j\"/g, "\"synced\"")

	return final;
}
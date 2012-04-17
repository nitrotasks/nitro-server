// Initiate socket.io
var express = require('express').createServer(),
	// socket = require("socket.io"),
	io = require('socket.io').listen(8080),
	$ = require('jquery');
	// dbox = require("dbox").app({ "app_key": "da4u54t1irdahco", "app_secret": "3ydqe041ogqe1zq" });

// io = socket.listen(express);
// io.configure(function() { 
//   io.set("transports", ["xhr-polling"]); 
//   io.set("polling duration", 10); 
// });

// Create server
var server = {
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
	queue: {},
	prefs: {
		deleteWarnings: false,
		gpu: false,
		nextAmount: "threeItems",
		over50: true,
		lang: "english",
		theme: "default",
		sync: 'manual'
	}
}

// Client connects to server
io.sockets.on('connection', function(socket) {

/*	var client;

	dbox.request_token(function(status, request_token){
		socket.emit('token', request_token.authorize_url);
		socket.on('allowed', function() {

			console.log("ALLOWED")

			dbox.access_token(request_token, function(status, access_token){

				console.log("GOT CLIENT")
			 	client = dbox.createClient(access_token);

			 	client.put("foo/hello.txt", "here is some text", function(status, reply){
				 	console.log(reply)
				})
			});

		});
	});

	dbox.access_token(request_token, function(status, access_token){
		token.access = access_token;
	})*/

	// Client uploads data to server
	socket.on('upload', function(data) {

		// Merge data with server
		merge(data, function() {
			// Send data back to client
			socket.emit('download', server);
		});
	});
});

// port = process.env.PORT || 3000;
// express.listen(port);

function clone(input) {
	return JSON.parse(JSON.stringify(input));
}

function merge(client, callback) {

	// If computer has never been synced before
	if(client.prefs.hasOwnProperty('synced')) {

		// Loop through each task
		for(var task in client.tasks) {

			// Does not sync the length key
			if(task != 'length') {

				// Mess with task id's
				client.tasks[parseInt(task) + server.tasks.length] = clone(client.tasks[task]);
				delete client.tasks[task]

			}
		}

		// Remove the synced property
		delete client.prefs.synced;
	}

	// Loop through each list
	for(var list in client.lists.items) {

		// Check to see if list exist on server
		if(!server.lists.items.hasOwnProperty(list)) {

			// If the list doesn't exist on the server, create it
			server.lists.items[server.lists.items.length] = {
				name: "",
				order: [],
				time: 0
			}

			// Copy the name and timestamp over
			server.lists.items[server.lists.items.length].name = client.lists.items[list].name;
			server.lists.items[server.lists.items.length].time = client.lists.items[list].time;

			// Update order
			server.lists.order.push(list);

			server.lists.items.length++;

		// Check to see if list was updated
		} else {

			for(var key in client.lists.items[list].time) {
				if(client.lists.items[list].time[key] > server.lists.items[list].time[key]) {

					// If so, update list key and time
					server.lists.items[list][key] = client.lists.items[list][key];
					server.lists.items[list].time[key] = client.lists.items[list].time[key];
				}
			}
		}
	}

	// Loop through each task
	for(var task in client.tasks) {

		// Do not sync the tasks.length propery
		// This should only be modified by the server side cli.js
		if(task != 'length') {

			// If task does not exist on the server
			if(!server.tasks.hasOwnProperty(task)) {

				// If task hasn't been deleted
				if(!client.tasks[task].hasOwnProperty('deleted')) {

					// Add the task to the server
					cli.addTask("New Task", client.tasks[task].list);
					server.tasks[task] = clone(client.tasks[task]);

					// Calculate date
					cli.calc.date(task);

					// Calculate Today etc? - Do later
					cli.today(task).calculate();

				// The task is new, but the client deleted it
				} else {

					// Add the task to the server, but don't touch lists and stuff
					server.tasks[task] = clone(client.tasks[task]);

				}

			// Task was deleted on computer but not on the server
			} else if(client.tasks[task].hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

				// We use this to check whether the task was modified AFTER it was deleted
				var deleteTask = true;

				// Loop through each attribute on server
				for(var key in server.tasks[task]) {

					// Check if server task was modified after task was deleted
					if(server.tasks[task].time[key] > client.tasks[task].deleted) {

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

			// Task is deleted on the server and the computer
			} else if(client.tasks[task].hasOwnProperty('deleted') && server.tasks[task].hasOwnProperty('deleted')){

				// Use the latest time stamp
				if(client.tasks[task].deleted > server.tasks[task].deleted) {

					// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
					server.tasks[task].deleted = client.tasks[task].deleted;

				}

			} else {

				//Stores the Attrs we'll be needing later
				var changedAttrs = [];

				// Loop through each attribute on computer
				for(var key in client.tasks[task]) {

					//Don't loop through timestamps
					if (key != 'time') {

						// Check if task was deleted on server or 
						 if (server.tasks[task].hasOwnProperty('deleted')) {

							// Check if task was modified after it was deleted
							if(client.tasks[task].time[key] > server.tasks[task].deleted) {

								// Update the server with the entire task (including attributes and timestamps)
								server.tasks[task] = client.tasks[task];

								//Breaks, we only need to do the thing once.
								break;
							}

						// Task has not been deleted
						} else {

							// If the attribute was updated after the server
							if(client.tasks[task].time[key] > server.tasks[task].time[key]) {


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
						console.log("The logged one was changed", task);
						cli.logbook(task)
						cli.logbook(task)
					} else if(changedAttrs.indexOf('date') != -1 || changedAttrs.indexOf('showInToday') != -1) {
						// Date is changed
						console.log('The date was changed');
						cli.calc.date(task);
						cli.today(task).calculate();
					} else if(changedAttrs.indexOf('today') != -1) {
						// Today
						console.log('Today was changed');
						cli.today(task).calculate();
					}

					if(changedAttrs.indexOf('list') != -1) {
						// List
						console.log('The list was changed')
						cli.moveTask(task, client.tasks[task].list)
					}
				}
			}
		}
	}

	console.log(server.lists.items['1'].order)

	// Update length
	server.tasks.length = 0;
	for (i in server.tasks) {
		if (server.tasks.hasOwnProperty(i) && i != 'length') {
			server.tasks.length++;
		}
	}

	// Get rid of duplicates TODO: just fix sync so it doesn't have duplicates
	// for(var list in server.lists.items) {
	// 	if(list != 'length') server.lists.items[list].order = eliminateDuplicates(server.lists.items[list].order);
	// }

	console.log(server.lists.items['1'].order)

	callback();
}

var cli = {
	escape: function(str) {
		//Regexes a bunch of shit that breaks the Linux version

		if (typeof str == 'string') {
			//Backslash, Pipe, newline, quote
			str = str.replace(/\\/g, "&#92;").replace(/\|/g, "&#124").replace(/\"/g, "&#34;").replace(/\'/g, "&#39;");
			return str;
		} else {
			return str;
		}
		
	},
	addTask: function(name, list) {
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
				logged: 0,
			}
		};

		if (list == 'today') {
			cli.today(id).add();
		} else {
			//Pushes to array
			var verify = true;
			for(var i in server.lists.items[list].order) {
				if(i == id) verify = false;
			}
			if(verify) server.lists.items[list].order.push(id);
		};

		//Saves to disk
		// server.save();

		//Returns something
		console.log("Created Task: '" + name + "' with id: " + id + " in list: " + list);

	},
	deleteTask: function(id) {
		var task = cli.taskData(id).display();

		cli.calc.removeFromList(id, task.list);

		//Changes task List to 0 so today.calculate removes it.
		task.list = 0;
		cli.taskData(id).edit(task);

		//Removes from Today and Next
		cli.today(id).calculate();

		//Removes from list
		cli.calc.removeFromList(id, 0);

		//Deletes Data - nonononononono
		// delete server.tasks[id];

		//Saves
		// server.save();
	},
	populate: function(type, query) {
		query = cli.escape(query);
		// Displays a list
		switch(type) {
			case "list":
				// Get tasks from list

				switch(query) {
					case "logbook":

						var logbook = [];

						for (var t = 0; t < server.tasks.length; t++) {
							// looooooping through the tasks
							if (server.tasks[t]) {
								if(server.tasks[t].logged) {
									var data = cli.taskData(t).display()
									//remove today & date data
									data.date = '';
									data.today = 'false';
									cli.taskData(t).edit(data);

									logbook.push(t)
								}
							}
						}

						return logbook;

						break;
					default:
						if(query in server.lists.items) return server.lists.items[query].order;
						else return [];
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
						if(!server.tasks[t].logged) {

							var pass1 = [],
								pass2  = true;

							// Loop through each word in the query
							for (var q = 0; q < query.length; q++) {

								// Create new search
								search = new RegExp(query[q], 'i');

								// Search
								if (search.test(server.tasks[t]['content'] + server.tasks[t]['notes'])) pass1.push(true);
								else pass1.push(false);
							}

							// This makes sure that the task has matched each word in the query
							for (var p = 0; p < pass1.length; p++) {
								if(pass1[p] == false) pass2 = false;
							}

							// If all terms match then add task to the results array
							if(pass2) results.push(t)
						}
					}
				}
				return results;
		}
	},
	moveTask: function(id, list) {
		// Moves task to list

		var task = cli.taskData(id).display(),
			lists = server.lists.items

		// Remove task from old list
		cli.calc.removeFromList(id, task.list);

		// Add task to new list
		var verify = true;
		for(var i in server.lists.items[list].order) {
			if(i == id) verify = false;
		}
		if(verify) lists[list].order.push(id);

		// Update task.list
		task.list = list;

		cli.today(id).calculate();

		//If it's dropped in Someday, we strip the date & today
		if (list == 'someday') {
			task.date = '';
			cli.today(id).remove();
		}

		// Save
		cli.taskData(id).edit(task);
		server.lists.items = lists;
		// server.save();

		console.log('The task with the id: ' + id + ' has been moved to the ' + list + ' list')
	},
	today: function(id) {
		return {
			add: function() {
				// Adds to Today Manually
				var task = cli.taskData(id).display();

				task.today = 'manual';
				task.showInToday = '1';
				cli.today(id).calculate();

			},
			remove: function() {
				// Removes from Today Manually
				var task = cli.taskData(id).display();

				task.today = 'false';
				task.showInToday = 'none';

				if (task.list == 'today') {
					task.list = 'next';
				};

				cli.today(id).calculate();
			},
			calculate: function() {				 
				 
				//Removes from Today & Next
				var task = cli.taskData(id).display(),
					lists = server.lists.items;
				
				// Remove task from Today
				cli.calc.removeFromList(id, 'today');
				
				// Remove task from Next
				cli.calc.removeFromList(id, 'next');
				
				console.log('List: ' + task.list);

				//If the task is due to be deleted, then delete it
				if (task.list == 0) {
					return;
				}

				//If task is in logbook, do nothing
				if (task.logged) {
					return;
				}

				//Calculates date. Changes today Status
				cli.calc.date(id);
				
				//If the list is today, we place back in today & next
				if (task.list == 'today') {
					
					lists.today.order.unshift(id);
					lists.next.order.unshift(id);

					console.log('List in today, placed in today');
				} else {
					//If the task is either manually in today, or has a date, we place in Today and next
					if (task.today == 'manual' || task.today == 'yesAuto') {
						//Adds to Today & Next arrays
						console.log('List either manually set or Date set. In today');
						lists.today.order.unshift(id);
						lists.next.order.unshift(id);
					} else {
						console.log('Not in today');
						//Do nothing unless in Next list
						if (task.list == 'next') {
							//Adds to Next array
							lists.next.order.unshift(id);
						};
					};
				}

				// Crazy bug
				server.lists.items.today.order = eliminateDuplicates(server.lists.items.today.order);
				server.lists.items.next.order = eliminateDuplicates(server.lists.items.next.order);
				
				//Saves data
				// server.save();
			}
		}
	},
	logbook: function(id) {
		// Toggles an item to/from the logbook

		var task = cli.taskData(id).display(),
			lists = server.lists.items;

		// Check if task exists
		if(!task) {
			console.log('No task with id: ' + id + ' exists');
			return;
		}

		task.logged = !task.logged;

		//If list is deleted, set to next
		if(!(task.list in lists)) task.list = 'next';

		if(task.logged) { // Uncomplete -> Complete
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

		cli.taskData(id).edit(task);
		server.lists.items = lists;
		// server.save();
	},
	priority: function(id) {
		return {
			get: function() {
				var priority = server.tasks[id].priority;
				return priority;
			},
			set: function() {
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
				
				server.tasks[id].priority = priority;
				// server.save();
				return priority;
			}
		}
	},
	taskData: function(id) {
		return {
			display: function () {
				// Returns taskData as object
				return server.tasks[id];

			},
			edit: function(obj) {
				// Edit taskData
				$.each(obj, function(i, value) { 
  					if (typeof value == "string") {
  						obj[i] = cli.escape(value);
  					}
				});

				server.tasks[id] = obj;
				// server.save();
				
			}
		};
	},
	list: function(id, name) {
		name = cli.escape(name);

		return {
			add: function() {
				// Adds a list
				var newId = server.lists.items.length;

				//Chucks data in object
				server.lists.items[newId] = { name: name, order: []};

				//Adds to order array
				server.lists.order.push(newId);

				//Returns something
				console.log("Created List: '" + name + "' with id: " + newId);

				//Updates Total
				server.lists.items.length++;
				// server.save();
			},
			rename: function() {
				// Renames a list
				server.lists.items[id].name = name;

				//Saves to localStorage
				// server.save();

				//Returns something
				console.log("Renamed List: " + id + " to: '" + name + "'");
			},
			delete: function() {
				//Deletes data in list
				for (var i=0; i<server.lists.items[id].order.length; i++) {
					cli.today(server.lists.items[id].order[i]).remove();
					delete server.tasks[server.lists.items[id].order[i]];
				};


				//Deletes actual list
				delete server.lists.items[id];
				server.lists.order.splice(jQuery.inArray(parseInt(id), server.lists.order), 1);

				//Saves to disk
				// server.save();

				//Returns something
				console.log("Deleted List: " + id);
			},
			taskOrder: function(order) {
				//Order of tasks
				server.lists.items[id].order = order;
				// server.save();
			},
			order: function(order) {
				// Order of lists
				server.lists.order = order;
				// server.save();
			}
		}
	},
	calc: {
		//Another object where calculations are done
		removeFromList: function(id, list) {

			var task = cli.taskData(id).display(),
				lists = server.lists.items;

			// DOES NOT REMOVE LIST FROM TASK
			// List must be manually removed from task.list
			// task.list = '';
			
			// Remove task from Today
			for(var i = 0; i < lists[list].order.length; i++) {
				if(lists[list].order[i] == id) {
					lists[list].order.splice(i, 1);
					console.log('Removed: ' + id + ' from ' + list);
				};
			};

			// cli.taskData(id).edit(task);
			server.lists.items = lists;
			// server.save();
		},

		date: function(id) {
			var task = cli.taskData(id).display(),
			lists = server.lists.items;

			//If it's already in today, do nothing. If it doesn't have a date, do nothing.
			if (task.today != 'manual' && task.date != '') {
				if (task.showInToday == 'none') {
					//Remove from today
					task.today = 'false';
					console.log('Specified to not show in today')

					//Remove from queue
					if (server.queue[id]) {
						delete server.queue[id];
					};

				} else {
					console.log('Due date, running queue function')

					//Due date + days to show in today
					var date = new Date(task.date);
					date.setDate(date.getDate() - parseInt(task.showInToday));
					var final = (date.getMonth() + 1) + '/' + date.getDate() + '/' + date.getUTCFullYear();

					server.queue[id] = final;

					// server.save();

					//Refreshes Date Queue
					cli.calc.todayQueue.refresh();
				};
			};
		},
		dateConvert: function(olddate) {
			//Due date + days to show in today
			var date = new Date(olddate);
			var final = (date.getMonth() + 1) + '/' + date.getDate() + '/' + date.getUTCFullYear();

			return final;
		},
		prettyDate: {
			convert: function(date) {
				date = date.split('/');
				date = new Date(date[2], date[0] - 1, date[1]);
				//If it's the current year, don't add the year.
				if (date.getFullYear() == new Date().getFullYear()) {
					date = date.toDateString().substring(4).replace(" 0"," ").replace(" " + new Date().getFullYear(), '');
				} else {
					date = date.toDateString().substring(4).replace(" 0"," ");
				};
				return date;
			},
			difference: function(date) {

				if (date == '') {
					return ['', '']
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
					if(difference < 0) {
						// Overdue
						difference = Math.abs(difference);
						if(difference != 1) return [$.i18n._('daysOverdue', [difference]), 'due'];
						else return [$.i18n._('dayOverdue'), 'due'];
					} else if(difference == 0) {
						// Due
						return ["due today", 'due']
					} else if(difference < 15) {
						// Due in the next 15 days
						if(difference != 1) return [$.i18n._('daysLeft', [difference]), ''];
						else return [$.i18n._('dayLeft'), '']
					} else {
						// Due after 15 days
						var month = $.i18n._('month');
						return [month[date.getMonth()] + " " + date.getDate(), ''];
					};	
				};
			}
		},
		todayQueue: {
			
			refresh: function() {

				for (var key in server.queue) {
					if (server.queue.hasOwnProperty(key)) {
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
					    	if (server.tasks[key].list != 'next') {
					    		server.lists.items.next.order.push(key);
					    	}

					    	delete server.queue[key];

					    } else {
							//Wait till tomorrow.
							server.tasks[key].today = 'noAuto';
					    };
						// server.save();
					};
				};
			}
		}
	},

	storage: {

		save: function() {
			//Saves to localStorage
			// Not really
		}
	}
}

function eliminateDuplicates(arr) {
  var i,
      len=arr.length,
      out=[],
      obj={};

  for (i=0;i<len;i++) {
    obj[arr[i]]=0;
  }
  for (i in obj) {
    out.push(i);
  }
  return out;
}
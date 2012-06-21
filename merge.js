// Create server
emptyServer = {
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
	},
	version: settings.version
};

mergeDB = function(server, client, callback) {

	msg(server.version)

	// Check for version number
	if(client.stats.version != "1.4") {
		// Add a task telling them to update...
		var id = client.tasks.length
		client.tasks[id] = {
			content: "IMPORTANT: Please upgrade to Nitro 1.4 to continue using sync.",
			priority: "important",
			date: "",
			notes: "",
			today: "manual",
			showInToday: "1",
			list: "today",
			logged: false,
				time: {
				content: 1340088252145,
				priority: 1340088209109,
				date: 1340088214848,
				notes: 0,
				today: 1340088214857,
				showInToday: 1340088214857,
				list: 1340088214857,
				logged: 0
			},
			synced: false
		}
		client.tasks.length++
		client.lists.items.today.order.unshift(id)
		callback(client)
		return
	}
	if(server.version !== "1.4") {
		upgradeDB(server)
	}

	msg(JSON.stringify(client, null, 2))
	msg("=============================")
	msg(JSON.stringify(server, null, 2))

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
						tags: [],
						time: {
							content: 0,
							priority: 0,
							date: 0,
							notes: 0,
							list: 0,
							logged: 0,
							tags: 0
						},
						synced: false
					}

					//Pushes to array
					server.lists.items[list].order.unshift(taskId)
					// server.save()
					msg('Adding Task: ' + name + ' into list: ' + list)

					return taskId
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
						msg('Logged ' + id);
						// server.save(['tasks', id, 'logged']);
					}

					// Taking a task out of the logbook
					if(server.tasks[id].list == list && server.tasks[id].logged && list != 'logbook') {
						msg("Unlogging task")
						server.tasks[id].logged = false;
						// server.save(['tasks', id, 'logged']);
					} else if (list === 'trash') {
						//Remove from list
						server.lists.items[old].order.remove(id);
						// delete server.tasks[id];
						server.tasks[id] = {deleted: 1};
						msg('Deleted: ' + id);
						// Saves - but doesn't mess with timestamps
						// server.save();
					} else {
						//Remove from list
						server.lists.items[old].order.remove(id);
						//Move to other list
						server.lists.items[list].order.unshift(id);
						server.tasks[id].list = list;
						msg('Moved: ' + id + ' to ' + list);
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

					msg(JSON.stringify(server.lists.order))

					//Deletes List
					//server.lists.items[id] = {deleted: core.timestamp()};
					server.lists.items[id] = {deleted: time};
					// server.save();
				}
			}
		}
	}	

	// Loop through each list
	for (var list in client.lists.items) {

		if (list !== 'length') {

			msg("Merging list: "+list)

			var _this = client.lists.items[list]


			//
			//	Synced on client
			// 	Doesn't exist on Sever
			// 	
			// 	Hacky fix for when users mess with stuff they shouldn't
			// 	Like switching between Dropbox and Ubuntu
			//
			if(_this.synced === true && !server.lists.items.hasOwnProperty(list)) _this.synced = false



			// 
			// 	New list
			// 

			if (_this.synced === false) {

				msg("List '" + list + "' has never been synced before")

				// List is now synced so set it to true
				_this.synced = true

				// If a list with that ID already exists on the server
				if (server.lists.items.hasOwnProperty(list)) {

					msg("List '" + list + "' already exists on the server")

					// Change the list ID
					var newID = server.lists.items.length
					client.lists.items[newID] = clone(_this)

					for(var task = 0; task < _this.order.length; task++) {
						msg("Task in list: " + task)
						task = _this.order[task]
						client.tasks[task].list = newID
						client.tasks[task].time.list = Date.now()
					}

					delete _this
					msg("List '" + list + "' has been moved to '" + server.lists.items.length + "'")
					list = server.lists.items.length

				} else {
					msg("List '" + list + "' does not exist on server. Adding to server as: " + server.lists.items.length)

					if(list != server.lists.items.length) {
						for(var i = 0; i < _this.order.length; i++) {
							task = _this.order[i]
							client.tasks[task].list = server.lists.items.length
							client.tasks[task].time.list = Date.now()
						}
					}
				}

				// If the list doesn't exist on the server, create it
				server.lists.items[server.lists.items.length] = {
					name: _this.name,
					order: [],
					time: _this.time,
					synced: true
				}

				// Update order
				server.lists.order.push(Number(list))
				server.lists.items.length++



			//
			//	Deleted on Client
			// 	Doesn't exist on Sever
			//

			} else if (_this.hasOwnProperty('deleted') && !server.lists.items.hasOwnProperty(list)) {

				msg("List "+list+" Is Deleted On The Client But Doesn't Exist On The Server")

				// Copy the deleted timestamp over
				server.lists.items[list] = {deleted: _this.deleted}
				server.lists.items.length++



			// 
			// 	Deleted on Client
			// 	Exists on Sever
			// 

			 } else if (_this.hasOwnProperty('deleted') && !server.lists.items[list].hasOwnProperty('deleted')) {

				msg("List " + list + " Is Deleted On The Client And But Not On The Server")

				var deleteList = true
				for(var key in server.lists.items[list].time) {
					if(server.lists.items[list].time[key] > _this.deleted) deleteList = false
				}
				if(deleteList) core.list(list).delete(_this.deleted)



			// 
			// 	Deleted on Client
			// 	Deleted on Server
			// 

			} else if (server.lists.items[list].hasOwnProperty('deleted') && _this.hasOwnProperty('deleted')) {

				msg("List '" + list + "' is deleted on the server and the computer")

				if (_this.deleted > server.lists.items[list].deleted) {
					msg("List '" + list + "' is deleted, but has a newer timestamp")
					server.lists.items[list].deleted = _this.deleted
				}



			// 
			// 	Exists on Client
			// 	Deleted on Sever
			//

			} else if (server.lists.items[list].hasOwnProperty('deleted') && client.lists.items.hasOwnProperty(list)) {

				msg("List " + list + " is deleted on the server and exists on the client")

				var keepList = false
				for(var key in _this.time) {
					if(_this.time[key] > server.lists.items[list].deleted) keepList = true
				}
				if(keepList) server.lists.items[list] = clone(_this)



			// 
			// 	Exists on Client
			// 	Exists on Sever
			//

			} else if (server.lists.items.hasOwnProperty(list)) {

				msg("List '" + list + "' exists on server.")

				for(var key in _this.time) {

					if(key != 'order') { // Don't try and overwrite list order

						if (_this.time[key] > server.lists.items[list].time[key]) {

							msg("The key '" + key + "' in list '" + list + "' has been modified.")

							// If so, update list key and time
							server.lists.items[list][key] = _this[key]
							server.lists.items[list].time[key] = _this.time[key]

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

				msg("Task '" + task + "' has never been synced before");

				// Task is going to be added to the server so we delete the synced property
				client.tasks[task].synced = true;

				// If task already exists on the server (Don't be fooled, it's a different task...)
				if (server.tasks.hasOwnProperty(task)) {

					msg("A task with the ID '" + task + "' already exists on the server");

					// Does not mess with ID's if it isn't going to change
					if (server.tasks.length !== Number(task)) {

						// Add task to task (ID + server.tasks.length)
						client.tasks[server.tasks.length] = clone(client.tasks[task]);
						delete client.tasks[task];

						msg("Task '" + task + "' has been moved to task '" + server.tasks.length  + "'");

						task = server.tasks.length;

					}
				}

				// If task hasn't been deleted
				if (!client.tasks[task].hasOwnProperty('deleted')) {

					msg("Task '" + task + "' is being added to the server.");

					// Add the task to the server
					core.task().add("New Task", client.tasks[task].list);
					server.tasks[task] = clone(client.tasks[task]);

					// Fix task length
					fixLength(server.tasks);

				// The task is new, but the client deleted it
				} else {

					msg("Task '" + task + "' is new, but the client deleted it");

					// Add the task to the server, but don't touch lists and stuff
					server.tasks[task] = clone(client.tasks[task]);

				}


			/***** TASK DOESN'T EXIST ON SERVER FOR SOME REASON -- BUG *****/
			} else if (!server.tasks.hasOwnProperty(task)) {

				msg("Task " + task + " doesn't exist on server. It should, but it doesn't.");

				if(client.tasks[task].hasOwnProperty('deleted')) {

					msg("Task " + task + " was deleted before it was sunk");

					server.tasks[task] = {deleted: client.tasks[task].deleted};
				}


			/***** CLIENT DELETED TASK *****/

			// Task was deleted on computer but not on the server
			} else if (client.tasks[task].hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

				msg("Task '" + task + "' was deleted on computer but not on the server");

				// We use this to check whether the task was modified AFTER it was deleted
				var deleteTask = true;

				// Loop through each attribute on server
				for(var key in server.tasks[task]) {

					// Check if server task was modified after task was deleted
					if (server.tasks[task].time[key] > client.tasks[task].deleted) {

						msg("Task '" + task + "' was modified after task was deleted");

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

				msg("Task '" + task + "' is deleted on the server and the computer");

				// Use the latest time stamp
				if (client.tasks[task].deleted > server.tasks[task].deleted) {

					msg("Task '" + task + "' is deleted, but has a newer timestamp");

					// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
					server.tasks[task].deleted = client.tasks[task].deleted;

				}

			/***** OLD TASK THAT HASN'T BEEN DELETED BUT POSSIBLY MODIFIED *****/

			} else {

				msg("Task '" + task + "' exists on the server and hasn't been deleted");

				//Stores the Attrs we'll be needing later
				var changedAttrs = [];

				// Loop through each attribute on computer
				for(var key in client.tasks[task]) {

					//Don't loop through timestamps
					if (key !== 'time') {

						// Check if task was deleted on server or
						if (server.tasks[task].hasOwnProperty('deleted')) {

							msg("Task '" + task + "' was deleted on the server");

							// Check if task was modified after it was deleted
							if (client.tasks[task].time[key] > server.tasks[task].deleted) {

								msg("Task " + task + " was modified on the client after it was deleted on the server");

								// Update the server with the entire task (including attributes and timestamps)
								server.tasks[task] = client.tasks[task];

								//Breaks, we only need to do the thing once.
								break;
							}

						// Task has not been deleted
						} else {

							// If the attribute was updated after the server
							if (client.tasks[task].time[key] > server.tasks[task].time[key]) {

								msg("Key '" + key + "'  in task " + task + " has been updated by the client");

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
						msg("Task " + task + " has been updated --> DATE");
						//core.calc.date(task);
						//core.today(task).calculate();
					} else if (changedAttrs.indexOf('today') != -1) {
						// Today
						msg("Task " + task + " has been updated --> TODAY");
						//core.today(task).calculate();
					}

					if (changedAttrs.indexOf('list') != -1) {
						// List
						msg("Task " + task + " has been updated --> LIST");
						core.task(task).move(client.tasks[task].list);
						msg(server.lists.items[client.tasks[task].list].order)
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

				msg("Task '" + task + "' has never been synced before");

				// Task is going to be added to the server so we delete the synced property
				client.lists.scheduled[task].synced = true;

				// If task already exists on the server (Don't be fooled, it's a different task...)
				if (server.lists.scheduled.hasOwnProperty(task)) {

					msg("A task with the ID '" + task + "' already exists on the server");

					// Does not mess with ID's if it isn't going to change
					if (server.lists.scheduled.length !== Number(task)) {

						// Add task to task (ID + server.lists.scheduled.length)
						client.lists.scheduled[server.lists.scheduled.length] = clone(client.lists.scheduled[task]);
						delete client.lists.scheduled[task];

						msg("Task '" + task + "' has been moved to task '" + server.lists.scheduled.length  + "'");

						task = server.lists.scheduled.length;

					}
				}

				// If task hasn't been deleted
				if (!client.lists.scheduled[task].hasOwnProperty('deleted')) {

					msg("Task '" + task + "' is being added to the server.");

					// Add the task to the server
					core.scheduled.add("New Task", client.lists.scheduled[task].type);
					server.lists.scheduled[task] = clone(client.lists.scheduled[task]);

					// Fix task length
					fixLength(server.lists.scheduled);

				// The task is new, but the client deleted it
				} else {

					msg("Task '" + task + "' is new, but the client deleted it");

					// Add the task to the server, but don't touch lists and stuff
					server.lists.scheduled[task] = clone(client.lists.scheduled[task]);

				}

			/***** TASK DOESN'T EXIST ON SERVER FOR SOME REASON -- BUG *****/
			} else if (!server.tasks.hasOwnProperty(task)) {

				msg("Task doesn't exist on server. It should, but it doesn't.");

				// Better just copy the task onto the server...
				server.lists.scheduled[task] = clone(client.lists.scheduled[task]);

			/***** CLIENT DELETED TASK *****/

			// Task was deleted on computer but not on the server
			} else if (client.lists.scheduled[task].hasOwnProperty('deleted') && !server.lists.scheduled[task].hasOwnProperty('deleted')) {

				msg("Task '" + task + "' was deleted on computer but not on the server");

				// We use this to check whether the task was modified AFTER it was deleted
				var deleteTask = true;

				// Loop through each attribute on server
				for(var key in server.lists.scheduled[task]) {

					// Check if server task was modified after task was deleted
					if (server.lists.scheduled[task].time[key] > client.lists.scheduled[task].deleted) {

						msg("Task '" + task + "' was modified after task was deleted");

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

				msg("Task '" + task + "' is deleted on the server and the computer");

				// Use the latest time stamp
				if (client.lists.scheduled[task].deleted > server.lists.scheduled[task].deleted) {

					msg("Task '" + task + "' is deleted, but has a newer timestamp");

					// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
					server.lists.scheduled[task].deleted = client.lists.scheduled[task].deleted;

				}

			/***** OLD TASK THAT HASN'T BEEN DELETED BUT POSSIBLY MODIFIED *****/

			} else {

				msg("Task '" + task + "' exists on the server and hasn't been deleted");

				// Loop through each attribute on computer
				for(var key in client.lists.scheduled[task]) {

					//Don't loop through timestamps
					if (key !== 'time') {

						// Check if task was deleted on server or
						if (server.lists.scheduled[task].hasOwnProperty('deleted')) {

							msg("Task '" + task + "' was deleted on the server");

							// Check if task was modified after it was deleted
							if (client.lists.scheduled[task].time[key] > server.lists.scheduled[task].deleted) {

								msg("Task " + task + " was modified on the client after it was deleted on the server");

								// Update the server with the entire task (including attributes and timestamps)
								server.lists.scheduled[task] = client.lists.scheduled[task];

								//Breaks, we only need to do the thing once.
								break;
							}

						// Task has not been deleted
						} else {

							// If the attribute was updated after the server
							if (client.lists.scheduled[task].time[key] > server.lists.scheduled[task].time[key]) {

								msg("Key '" + key + "'  in task " + task + " has been updated by the client");

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
				msg("List order: Same keys so going with latest version - Client")
				return [c.order, c.time];
			} else {
				msg("List order: Same keys so going with latest version - Server")
				return [s.order, s.time];
			}

		} else {

			// Crazy merging code
			msg("List order: Using crazy merging code")

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
	msg(JSON.stringify(server.lists))

	// Loop through each list (again)
	for (var list in client.lists.items) {
		list = list.toNum();
		if (list !== 'length' && !server.lists.items[list].hasOwnProperty('deleted') && !client.lists.items[list].hasOwnProperty('deleted')) {

			var c = {
				order: client.lists.items[list].order,
				time: client.lists.items[list].time.order
			},
			s = {
				order: server.lists.items[list].order,
				time: server.lists.items[list].time.order
			}

			var mergedListOrder = mergeOrder(c, s);

			msg(list)
			msg(JSON.stringify(c));
			msg(JSON.stringify(s));

			server.lists.items[list].order = mergedListOrder[0];
			server.lists.items[list].time.order = mergedListOrder[1];

		}
	}

	// Well it got this far without crashing
	server.version = settings.version

	callback(server);

}

// Fix the length of an object
fixLength  = function(obj) {
	// Update length
	[obj].length = 0;
	for (i in [obj]) {
		if ([obj].hasOwnProperty(i) && i !== 'length') {
			[obj].length++;
		}
	}
}

// Remove duplicates from an array
deDupe = function(arr) {
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
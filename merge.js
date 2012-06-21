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
	cleanDB(client)
	cleanDB(server)
	msg("=============================")
	msg(JSON.stringify(client, null, 2))

	// ----------------------------
	// CORE FUNCTIONS
    // ----------------------------

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
						synced: true
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


	// ----------------------------
	// LISTS
    // ----------------------------

	for (var list in client.lists.items) {

		if (list !== 'length') {

			msg("Merging list: "+list)

			var _this = client.lists.items[list]


			//
			//	Synced on client
			// 	Doesn't exist on Sever
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

					delete client.lists.items[list]
					msg("List '" + list + "' has been moved to '" + server.lists.items.length + "'")
					_this = client.lists.items[server.lists.items.length]

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
				for(var key in server.lists.items[list].time) {
					if(server.lists.items[list].time[key] > _this.deleted) {
						core.list(list).delete(_this.deleted)
						break
					}
				}



			// 
			// 	Deleted on Client
			// 	Deleted on Server
			// 

			} else if (server.lists.items[list].hasOwnProperty('deleted') && _this.hasOwnProperty('deleted')) {

				msg("List '" + list + "' is deleted on the server and the computer")
				if (_this.deleted > server.lists.items[list].deleted) server.lists.items[list].deleted = _this.deleted



			// 
			// 	Exists on Client
			// 	Deleted on Sever
			//

			} else if (server.lists.items[list].hasOwnProperty('deleted') && client.lists.items.hasOwnProperty(list)) {

				msg("List " + list + " is deleted on the server and exists on the client")
				for(var key in _this.time) {
					if(_this.time[key] > server.lists.items[list].deleted) {
						server.lists.items[list] = clone(_this)
						break
					}
				}



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


	// ----------------------------
	// TASKS
	// ----------------------------

	for(var task in client.tasks) {

		task = task.toNum()

		// Do not sync the tasks.length propery
		// This should only be modified by the server side core.js
		if (task !== 'length') {

			var _this = client.tasks[task]

			// 
			// Synced on Client
			// Doesn't exist on Server
			// 
			if(_this.synced === true && !server.tasks.hasOwnProperty(task)) _this.synced = false



			// 
			// Exists on Client
			// Doesn't exist on Server
			// 

			if (_this.synced === false) {

				msg("Task '" + task + "' has never been synced before")

				_this.synced = true

				// If that ID is already taken
				if (server.tasks.hasOwnProperty(task)) {

					msg("A task with the ID '" + task + "' already exists on the server")

					// Does not mess with ID's if it isn't going to change
					if (server.tasks.length !== Number(task)) {

						// Add task to task (ID + server.tasks.length)
						client.tasks[server.tasks.length] = clone(_this)
						delete client.tasks[task]
						msg("Task '" + task + "' has been moved to task '" + server.tasks.length  + "'")
						_this = client.tasks[server.tasks.length]
					}
				}

				msg("Task '" + task + "' is being added to the server.");

				core.task().add("New Task", _this.list)
				server.tasks[task] = clone(_this)

				// Fix task length
				fixLength(server.tasks)



			// 
			// 	Deleted on Client
			// 	Not on Server
			// 

			} else if(_this.hasOwnProperty('deleted') && !server.tasks.hasOwnProperty(task)) {

				msg("Task '" + task + "' is new, but the client deleted it")
				server.tasks[task] = { deleted: _this.deleted }
				server.tasks.length++




			// 
			// 	Deleted on Client
			// 	Exists on Server
			// 

			} else if (_this.hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

				msg("Task '" + task + "' was deleted on client but not on the server")
				for(var key in server.tasks[task].time) {
					if (server.tasks[task].time[key] > _this.deleted) {
						// Remove from lists
						core.task(task).move('trash', _this.deleted)
						// Update timestamp
						server.tasks[task] = {deleted: _this.deleted}
						break
					}
				}



			// 
			// 	Deleted on Client
			// 	Deleted on Server
			// 

			} else if (_this.hasOwnProperty('deleted') && server.tasks[task].hasOwnProperty('deleted')){

				msg("Task '" + task + "' is deleted on the server and the client")
				if (_this.deleted > server.tasks[task].deleted) server.tasks[task].deleted = _this.deleted




			// 
			// 	Exists on Client
			// 	Deleted on Server
			//

			} else if (!_this.hasOwnProperty('deleted') && server.tasks[task].hasOwnProperty('deleted')) {

				msg("Task '" + task + "' was deleted on the server")
				for(var key in _this.time) {
					if(_this.time[key] > server.tasks[task].deleted) {
						server.tasks[task] = clone(_this)
						break
					}
				}




			// 
			// 	Exists on Client
			// 	Exists on Server
			// 

			} else {

				msg("Task '" + task + "' exists on the server and hasn't been deleted")

				for(var key in _this) {

					// Don't loop through timestamps
					if (key !== 'time') {

						if (_this.time[key] > server.tasks[task].time[key]) {

							msg("Key '" + key + "'  in task " + task + " has been updated by the client")							

							if (key === 'list') {
								msg("Task " + task + " has been moved to a new list")
								core.task(task).move(_this.list);
							} else {
								server.tasks[task][key] = _this[key]
							}

							// Update timestamp
							server.tasks[task].time[key] = _this.time[key]

						}
					}
				}
			}
		}
	}




	// ----------------------------
	// TASK AND LIST ORDER
	// ----------------------------
	

	// Fix task length
	fixLength(server.tasks)


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
	}

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
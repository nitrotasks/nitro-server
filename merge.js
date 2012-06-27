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
			length: 0
		},
		time: 0
	},
	version: "1.4.3"
}

getVersion = function(v) {
	v = v || ""
	var s = v.split('.'), o = 0
	for (var i = 0; i < s.length; i++) {
		switch(i) {
			case 0:
				o += s[i] * 100
				break
			case 1:
				o += s[i] * 10
				break
			case 2:
				o += s[i] * 1
				break
		}
	}
	return o
}

mergeDB = function(server, client, callback) {

	// try {

	var version = {
		client: getVersion(client.stats.version),
		server: getVersion(server.version)
	}

	msg(version)

	// Earlier than 1.4
	if(version.client < 140) {
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
		callback(client, "error")
		return

	// Old client, new server
	} else if(version.client < 145 && version.server >= 145) {

		msg("Incompatible client and server")

		var id = client.tasks.length
		client.tasks[id] = {
			content: "IMPORTANT: Please upgrade to Nitro 1.4.5 to continue using sync.",
			priority: "high",
			date: "",
			notes: "",
			list: "today",
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
		}
		client.tasks.length++
		client.lists.items.today.order.unshift(id)
		callback(client, "error")
		return

	// Use legacy sync
	} else if(version.client < 145) {

		legacy_mergeDB(server, client, callback, version)
		return

	}

	// If the server is from before 1.4, upgrade it
	if(version.server < 140) {
		upgradeDB(server, version.server)
	}
	
	msg("Cleaning client")
	cleanDB(client)
	msg("Cleaning server")
	cleanDB(server)

	// ----------------------------
	// CORE FUNCTIONS
    // ----------------------------

	var core = {
		getID: function() {
			var bit = function() {
				return (Math.floor(Math.random() *36)).toString(36)
			},
			part = function() {
				return bit() + bit() + bit() + bit()
			}
			return part() + "-" + part() + "-" + part()
		},
		task: function(id) {
			return {
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

					var old = server.tasks[id].list

					// Dropping a task onto the Logbook completes it
					if(list == 'logbook' && !server.tasks[id].logged) {
						server.tasks[id].logged = 1
						msg('Logged ' + id)
					}

					// Taking a task out of the logbook
					if(server.tasks[id].list == list && server.tasks[id].logged && list != 'logbook') {
						msg("Unlogging task")
						server.tasks[id].logged = false;

					// Deleting a task
					} else if (list === 'trash') {
						// Remove from list
						if(server.lists.items.hasOwnProperty(old)) {
							if(!server.lists.items[old].hasOwnProperty('deleted')) {
								server.lists.items[old].order.remove(id);		
							}
						}
						// Delete
						server.tasks[id] = {deleted: 1};
						msg('Deleted: ' + id);
					} else {
						//Remove from list
						if(server.lists.items.hasOwnProperty(old)) {
							if(!server.lists.items[old].hasOwnProperty('deleted')) {
								server.lists.items[old].order.remove(id);		
							}
						}
						//Move to other list
						server.lists.items[list].order.unshift(id);
						server.tasks[id].list = list;
						msg('Moved: ' + id + ' to ' + list);
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

		msg("Merging list: "+list)

		var _this = client.lists.items[list]




		// 
		// 	Exists on client
		// 	Doesn't exist on server
		// 

		if (!_this.hasOwnProperty('deleted') && !server.lists.items.hasOwnProperty(list)) {

			msg("Adding " + list + " to server")

			// If the list doesn't exist on the server, create it
			server.lists.items[list] = {
				name: _this.name,
				order: [],
				time: _this.time
			}

			// Update list order
			server.lists.order.push(list)



		//
		//	Deleted on Client
		// 	Doesn't exist on Sever
		//

		} else if (_this.hasOwnProperty('deleted') && !server.lists.items.hasOwnProperty(list)) {

			msg("List "+list+" Is Deleted On The Client But Doesn't Exist On The Server")

			// Copy the deleted timestamp over
			server.lists.items[list] = {deleted: _this.deleted}



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


	// ----------------------------
	// TASKS
	// ----------------------------

	for(var task in client.tasks) {

		msg("Merging task: " + task)

		var _this = client.tasks[task]



		// 
		// Exists on Client
		// Doesn't exist on Server
		// 

		if (!_this.hasOwnProperty('deleted') && !server.tasks.hasOwnProperty(task)) {

			msg("Task '" + task + "' is being added to the server.")

			// Add task
			server.tasks[task] = clone(_this)

			// Add to list
			server.lists.items[_this.list].order.unshift(task)



		// 
		// 	Deleted on Client
		// 	Not on Server
		// 

		} else if(_this.hasOwnProperty('deleted') && !server.tasks.hasOwnProperty(task)) {

			msg("Task '" + task + "' is new, but the client deleted it")
			server.tasks[task] = { deleted: _this.deleted }




		// 
		// 	Deleted on Client
		// 	Exists on Server
		// 

		} else if (_this.hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

			msg("Task '" + task + "' was deleted on client but not on the server")
			var deleteTask = true
			for(var key in server.tasks[task].time) {
				if (server.tasks[task].time[key] > _this.deleted) deleteTask = false
			}
			if(deleteTask) {
				// Remove from lists
				core.task(task).move('trash', _this.deleted)
				// Update timestamp
				server.tasks[task] = {deleted: _this.deleted}
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




	// ----------------------------
	// TASK AND LIST ORDER
	// ----------------------------

	// Ghost lists
	for(var i = 0; i < server.lists.order.length; i++) {
		var _this = server.lists.order[i]
		if(!server.lists.items.hasOwnProperty(_this) || _this == 'today' || _this == 'next' || _this == 'logbook') {
			server.lists.order.splice(i, 1)
		}
	}

	// Hidden lists
	for(var i in server.lists.items) {
		var _this = server.lists.items[i]
		if(!_this.hasOwnProperty('deleted') && i != 'today' && i != 'next' && i != 'logbook') {
			var index = server.lists.order.indexOf(i)
			if(index < 0) {
				server.lists.order.push(i)
			}
		}
	}
	
	// MLO --> Merge List Order
	
	var mlo = { 
		client: {
			order: client.lists.order,
			time: client.lists.time
		},
		server: {
			order: server.lists.order,
			time: server.lists.time
		}
	}

	// Merge list order...
	mlo.run = function(c, s) {

		// Find diff
		var sD = ArrayDiff(s.order, c.order)
		var cD = ArrayDiff(c.order, s.order)

		// Check if only order has been changed
		var sameKeys = !sD.length && !cD.length

		// Only order has been changed
		if(sameKeys) {

			// Use newer timestamp
			if(c.time > s.time) {
				msg("List order: Same keys so going with latest version - Client")
				return [c.order, c.time]
			} else {
				msg("List order: Same keys so going with latest version - Server")
				return [s.order, s.time]
			}

		} else {

			// Crazy merging code
			msg("List order: Merging with algorithm")

			// Remove all keys that aren't in the server
			c.order = ArrayDiff(c.order, cD)

			for(var i = 0; i < sD.length; i++) {
				// Get the index of each key in the ServerDiff
				var index = s.order.indexOf(sD[i])
				// Inject the key into the client
				c.order.splice(index, 0, sD[i])
			}

			return [c.order, c.time]
		}
	}

	// Merge List Order
	mlo.result = mlo.run(mlo.client, mlo.server)
	server.lists.order = mlo.result[0]
	server.lists.time = mlo.result[1]

	// Merge Task Order (Uses same algorithm)
	for (var list in client.lists.items) {
		if (!server.lists.items[list].hasOwnProperty('deleted') && !client.lists.items[list].hasOwnProperty('deleted')) {

			mlo.client = {
				order: client.lists.items[list].order,
				time: client.lists.items[list].time.order
			}
			mlo.server = {
				order: server.lists.items[list].order,
				time: server.lists.items[list].time.order
			}
			mlo.result = mlo.run(mlo.client, mlo.server)

			server.lists.items[list].order = mlo.result[0]
			server.lists.items[list].time.order = mlo.result[1]

		}
	}

	// Well it got this far without crashing
	server.version = settings.version

	callback(server)

	// } catch(e) {}

}
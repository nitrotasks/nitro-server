cleanDB = function(d) {

	console.log("Running cleanDB")

	if(typeof d !== 'object') {
		console.log("Not even an object!? Giving up.")
		return
	}

// -------------------------------------------------
// 		VERSION 1.4.5
// -------------------------------------------------

	var defaults = {
		task: function() {
			return {
				content: 'New Task',
				priority: 'none',
				date: '',
				notes: '',
				list: 'today',
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
				}
			}
		},
		list: function() {
			return {
				name: 'New List',
				order: [],
				time: {
					name: 0,
					order: 0
				}
			}
		},
		smartlist: function() {
			return {
				order: [],
				time: {
					order: 0
				}
			}
		},
		server: function() {
			return {
				tasks: {},
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
						}
					},
					time: 0
				}
			}
		}
	}

	var o = new defaults.server()

	// Tasks
	var tasks
	if(d.hasOwnProperty('tasks')) tasks = d.tasks
	else tasks = new defaults.server().tasks

	for(var i in tasks) {
		
		// Only run if this is an object
		if(isObject(tasks[i])) var _this = tasks[i]
		else continue

		// Create default task
		o.tasks[i] = new defaults.task()

		// Deleted
		if(_this.hasOwnProperty('deleted')) {
			if(isNumber(_this.deleted) || isNumber(Number(_this.deleted))) {
				o.tasks[i] = {
					deleted: Number(_this.deleted)
				}
			} else {
				o.tasks[i] = {
					deleted: 0
				}
			}
		}

		// Content
		if(_this.hasOwnProperty('content')) {
			o.tasks[i].content = _this.content
		}

		// Priority
		if(_this.hasOwnProperty('priority')) {
			if(_this.priority === 'important') _this.priority = 'high'
			if(	_this.priority === 'none' || _this.priority === 'low' || _this.priority === 'medium' || _this.priority === 'high') {
				o.tasks[i].priority = _this.priority
			}
		}

		// Date
		if(_this.hasOwnProperty('date')) {
			if(isNumber(_this.date)) {
				o.tasks[i].date = _this.date
			} else {
				var Dt = new Date(_this.date).getTime()
				if(!isNaN(Dt)) {
					o.tasks[i].date = Dt
				}
			}
		}

		// Notes
		if(_this.hasOwnProperty('notes')) {
			o.tasks[i].notes = _this.notes
		}

		// Tags
		if(_this.hasOwnProperty('tags')) {
			if(isArray(_this.tags)) {
				o.tasks[i].tags = _this.tags.slice(0)
			}
		}

		// Logged
		if(_this.hasOwnProperty('logged')) {
			if(isNumber(_this.logged)) {
				o.tasks[i].logged = _this.logged
			} else if(_this.logged === 'true' || _this.logged === true) {
				o.tasks[i].logged = Date.now()
			}
		}

		// List -- May be able to remove this.
		if(_this.hasOwnProperty('list')) {
			o.tasks[i].list = _this.list
		}

		// Timestamps
		if(_this.hasOwnProperty('time')) {
			if(isObject(_this.time)) {
				for(var j in o.tasks[i].time) {
					if(isNumber(_this.time[j])) {
						o.tasks[i].time[j] = _this.time[j]
					} else {
						var Dt = new Date(_this.time[j]).getTime()
						if(isNumber(Dt)) {
							o.tasks[i].time[j] = Dt
						}
					}
				}
			}
		}
	}
	
	// Lists
	var lists
	if(d.hasOwnProperty('lists')) lists = d.lists
	else lists = new defaults.server().lists
	
	for(var i in lists.items) {
			
		if(isObject(lists.items[i])) var _this = lists.items[i]
		else continue

		// Create blank list
		if (i == 'today' || i == 'next' || i == 'logbook') {
			o.lists.items[i] = new defaults.smartlist()
		} else {
			o.lists.items[i] = new defaults.list()
		}
		
		// Deleted
		if(_this.hasOwnProperty('deleted')) {
			if(isNumber(Number(_this.deleted))) {
				o.lists.items[i] = {
					deleted: Number(_this.deleted)
				}
			} else {
				o.lists.items[i] = {
					deleted: 0
				}
			}
		}
			
		// Name
		if(_this.hasOwnProperty('name')) {
			o.lists.items[i].name = _this.name
		}		
		
		// Order
		if(_this.hasOwnProperty('order')) {
			if(isArray(_this.order)) {
				
				// All tasks in list
				for(var j = 0; j < _this.order.length; j++) {
					if(o.tasks.hasOwnProperty(_this.order[j])) {
						if(!o.tasks[_this.order[j]].hasOwnProperty('deleted')) {
							
							// Push to order
							o.lists.items[i].order.push(_this.order[j].toString())
							
							// Update task.list
							o.tasks[_this.order[j]].list = i
							
						}
					}
				}
			}
		}
		
		// Timestamps
		if(_this.hasOwnProperty('time')) {
			if(isObject(_this.time)) {
				for(var j in o.lists.items[i].time) {
					if(isNumber(_this.time[j])) {
						o.lists.items[i].time[j] = _this.time[j]
					} else {
						var Dt = new Date(_this.time[j]).getTime()
						if(isNumber(Dt)) {
							o.lists.items[i].time[j] = Dt
						}
					}
				}
			}
		}
	}
	
	// List order. Part I: Moving and Removing.
	for(var i = 0; i < lists.order.length; i++) {
		var _this = lists.order[i].toString()
		if(typeof _this == 'object' && o.lists.items.hasOwnProperty(_this) && _this != 'today' && _this != 'next' && _this != 'logbook') {
			if(!o.lists.items[_this].hasOwnProperty('deleted')) {
				o.lists.order.push(_this)
			}
		}
	}
	
	// List order. Part II: Hidden Lists.
	for(var i in o.lists.items) {
		var _this = o.lists.items[i]
		if(typeof _this == 'object' && !_this.hasOwnProperty('deleted') && i != 'today' && i != 'next' && i != 'logbook') {
			var index = o.lists.order.indexOf(i)
			if(index < 0) {
				o.lists.order.push(i.toString())
			}
		}
	}
	
	// List Time
	if(lists.hasOwnProperty('time')) {
		o.lists.time = Number(lists.time)
	}

	d.tasks = o.tasks
	d.lists = o.lists

}

// Upgrade localStorage from 1.3.1 to 1.4 to 1.45
upgradeDB = function(server, version) {

	console.log("Running database upgrade")

	var tasks = server.tasks,
		lists = server.lists

	var convertDate = function(date) {
		var date = new Date(date)
		return date.getTime()
	}

	// --------------------------
	// 		1.3 -> 1.4
	// --------------------------

	if(version < 140) {

		// --------------------------
		// 			LISTS
		// --------------------------

		// Fix up List 0
		lists.items[0] = {deleted: 0}

		// Add in logbook
		lists.items.logbook = {
			order: [],
			time: {
				order: 0
			}
		}

		lists.items[lists.items.length] = {
			name: 'Scheduled',
			order: [],
			time: {
				order: 0
			}
		}

		var scheduledID = lists.items.length
		lists.order.push(scheduledID)
		lists.items.length++


		// Fix Next list
		for (var i = lists.items.next.order.length - 1; i >= 0; i--) {
			var id = lists.items.next.order[i],
				_this = tasks[id]
			if(_this.list !== 'next') {
				lists.items.next.order.splice(i, 1)
			}
		};

		// Move scheduled tasks
		for (var key in lists.scheduled) {
			if(key !== 'length') {
				var _this = lists.scheduled[key],
					id = tasks.length
				tasks[id] = $.extend(true, {}, _this)
				_this = tasks[id]
				_this.list = scheduledID
				_this.tags = []
				if(_this.priority === 'important') _this.priority = 'high'
				delete _this.next
				delete _this.ends
				delete _this.type
				delete _this.recurType
				delete _this.recurInterval

				lists.items[scheduledID].order.push(id)
				tasks.length++
			}
		}

		delete lists.scheduled


		// --------------------------
		// 			TASKS
		// --------------------------

		for(var key in tasks) {

			if(key != 'length') {

				var _this = tasks[key]

				// Remove old properties
				delete _this.showInToday
				delete _this.today
				if(_this.hasOwnProperty('time')) {
					delete _this.time.showInToday
					delete _this.time.today
				}

				// Important -> High
				if(_this.priority === 'important') _this.priority = 'high'

				// Updated logged propety
				if(_this.logged === "true" || _this.logged === true) {
					_this.logged === Date.now()
					_this.list = 'logbook'
					lists.items.logbook.order.push(key)
				}

				// Add tags
				_this.tags = []

				// Update date property
				if(_this.date !== "" && _this.hasOwnProperty('date')) {
					_this.date = convertDate(_this.date)
				}

			}

		}


	// --------------------------
	// 		1.4 -> 1.4.5
	// --------------------------

	} else if (version < 145) {

		// Convert everything to strings
		// Maybe.

	}

	server.tasks = tasks
	server.lists = lists

}
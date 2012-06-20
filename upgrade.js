cleanDB = function(d) {

	console.log("Running cleanDB")

	if(typeof d !== 'object') {
		console.log("Not even an object!? Giving up.")
		return
	}

// -------------------------------------------------
// 		VERSION 1.4
// -------------------------------------------------

	var defaults = {
		task: {
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
			},
			synced: false
		}
	}

	var o = clone(emptyServer)

	// Tasks
	var tasks
	if(d.hasOwnProperty('tasks')) tasks = d.tasks
	else tasks = clone(emptyServer.tasks)

	// Find length
	var length = 0
	for(var k in tasks) {
		if(typeof _this === 'object') {
			if(Number(k) > length) length = Number(k)
		}
	}
	o.tasks.length = length
	for(var i = 0; i <= length; i++) {
		o.tasks[i] = clone(defaults.task)
		if(tasks.hasOwnProperty(i)) {
			var _this = tasks[i]
		} else {
			o.tasks[i] = { deleted: 0 }
			break
		}

		// Content
		if(_this.hasOwnProperty('content')) {
			if(typeof _this.content === 'string') {
				o.tasks[i].content = _this.content
			}
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
			} else if(typeof _this.date === 'string') {
				var Dt = new Date(_this.date).getTime()
				if(isNumber(Dt)) {
					o.tasks[i].date = Dt
				}
			}
		}

		// Notes
		if(_this.hasOwnProperty('notes')) {
			if(typeof _this.notes === 'string') {
				o.tasks[i].notes = _this.notes
			}
		}

		// Tags
		if(_this.hasOwnProperty('tags')) {
			if(isArray(_this.tags)) {
				for(var j = 0; j < _this.tags.length; j++) {
					if(typeof _this.tags[j] === 'string') {
						o.tasks[i].tags.push(_this.tags[j])
					}
				}
			}
		}

		// Logged
		if(_this.hasOwnProperty('logged')) {
			if(isNumber(_this.logged)) {
				o.tasks[i].logged = _this.logged
			} else if(_this.logged === 'true' || _this.logged === true) {
				o.tasks[i].logged = new Date().getTime()
			}
		}

		// List
		if(_this.hasOwnProperty('list')) {
			if(isNumber(Number(list))) {
				o.tasks[i].list = Number(_this.list)
			} else if(	_this.list === 'today' || _this.list === 'next' || _this.list === 'logbook') {
				o.tasks[i].list = _this.list
			}
		}

		// Timestamps
		if(_this.hasOwnProperty('time')) {
			if(isObject(_this.time)) {
				for(var j in o.tasks[i].time) {
					if(isNumber(_this.time[j])) {
						o.tasks[i].time[j] = _this.time[j]
					}
				}
			}
		}

		// Synced
		if(_this.hasOwnProperty('synced')) {
			if(typeof _this.synced === 'boolean') {
				o.tasks[i].synced = _this.synced
			}
		}

		// Scheduled
		if(_this.hasOwnProperty('type')) {
			if(_this.type === 'scheduled') {
				if(_this.hasOwnProperty('next')) {
					if(isNumber(_this.next)) {
						o.tasks[i].type = _this.type
						o.tasks[i].next = _this.next
					}
				}
			} else if(_this.type === 'recurring') {
				var valid = true
				if(_this.hasOwnProperty('next')) {
					if(!isNumber(_this.next)) valid = false
				} else valid = false
				if(_this.hasOwnProperty('ends')) {
					if(!isNumber(_this.ends) || _this.ends !== "" ) valid = false
				} else valid = false
				if(_this.hasOwnProperty('recurType')) {
					if(_this.recurType !== 'daily' || _this.recurType !== 'weekly' || _this.recurType !== 'monthly') valid = false
				} else valid = false
				if(_this.hasOwnProperty('recurInterval')) {
					if(!isArray(_this.recurInterval)) valid = false
				} else valid = false
				if(valid) {
					o.tasks[i].type = _this.type
					o.tasks[i].next = _this.next
					o.tasks[i].ends = _this.ends
					o.tasks[i].recurType = _this.recurType
					o.tasks[i].recurInterval = _this.recurInterval
				}
			}
		}
	}

	server.tasks = o.tasks
}


// Upgrade localStorage from 1.3.1 to 1.4
upgradeDB = function(server) {

	console.log("Running database upgrade")

	var tasks = server.tasks,
		lists = server.lists

	var convertDate = function(date) {
		var date = new Date(date)
		return date.getTime()
	}

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

	lists.items.scheduled = {
		order: [],
		time: {
			order: 0
		}
	}

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
			console.log(_this, id)
			tasks[id] = $.extend(true, {}, _this)
			_this = tasks[id]
			_this.tags = []
			if(_this.priority === 'important') _this.priority = 'high'
			if(_this.next) _this.next = convertDate(_this.next)
			if(_this.ends) _this.ends = convertDate(_this.ends)

			lists.items.scheduled.order.push(id)
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
				_this.logged === new Date().getTime()
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

	server.tasks = tasks
	server.lists = lists

}
// Upgrade localStorage from 1.3.1 to 1.4

upgrade = function(server) {

	console.log("Running database upgrade")

	var tasks = server.tasks,
		lists = server.lists,
		prefs = server.prefs

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
				_this.logged === core.timestamp()
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
	server.prefs = prefs

}
legacy_cleanDB = function(d) {

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
		},
		list: {
			name: 'New List',
			order: [],
			time: {
				name: 0,
				order: 0
			},
			synced: false
		},
		smartlist: {
			order: [],
			time: {
				order: 0
			}
		}
	}

	var o = clone(emptyServer)

	// Tasks
	var tasks
	if(d.hasOwnProperty('tasks')) tasks = d.tasks
	else tasks = clone(emptyServer.tasks)

	// Find length
	var length = -1
	for(var k in tasks) {
		if(typeof tasks[k] === 'object') {
			if(Number(k) > length) length = Number(k)
		}
	}
	length++
	o.tasks.length = length
	for(var i = 0; i < length; i++) {
		
		o.tasks[i] = clone(defaults.task)
		if(tasks.hasOwnProperty(i)) {
			var _this = tasks[i]
		} else {
			o.tasks[i] = { deleted: 0 }
		}

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
			} else {
				var Dt = new Date(_this.date).getTime()
				if(!isNaN(Dt)) {
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
				o.tasks[i].logged = Date.now()
			}
		}

		// List
		if(_this.hasOwnProperty('list')) {
			if(isNumber(Number(_this.list))) {
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
					} else {
						var Dt = new Date(_this.time[j]).getTime()
						if(isNumber(Dt)) {
							o.tasks[i].time[j] = Dt
						}
					}
				}
			}
		}

		// Synced
		if(_this.hasOwnProperty('synced')) {
			if(_this.synced === 'true') _this.synced = true
			if(typeof _this.synced === 'boolean') {
				o.tasks[i].synced = _this.synced
			}
		}
	}
	
	// Lists
	var lists
	if(d.hasOwnProperty('lists')) lists = d.lists
	else lists = clone(emptyServer.lists)
	
	// Find length
	length = -1
	for(var k in lists.items) {
		if(typeof lists.items[k] === 'object') {
			if(Number(k) > length) length = Number(k)
		}
	}
	length++
	o.lists.items.length = length
	
	var tempArray = ['today','next','logbook']
	for(var i = 0; i < length; i++) {
		tempArray.push(i)
	}
	
	for(var n = 0; n < tempArray.length; n++) {
		i = tempArray[n]
		
		// Create blank list
		if (i == 'today' || i == 'next' || i == 'logbook') {
			o.lists.items[i] = clone(defaults.smartlist)
			if(lists.items.hasOwnProperty(i)) {
				var _this = lists.items[i]
			}	
		} else {
			o.lists.items[i] = clone(defaults.list)
			if(lists.items.hasOwnProperty(i)) {
				var _this = lists.items[i]
			} else  {
				o.tasks[i] = { deleted: 0 }
			}	
		}
		
		// Deleted
		if(_this.hasOwnProperty('deleted')) {
			if(isNumber(_this.deleted) || isNumber(Number(_this.deleted))) {
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
			if(typeof _this.name === 'string') {
				o.lists.items[i].name = _this.name
			} else if(isNumber(_this.name)) {
				o.lists.items[i].name = _this.name.toString()
			}
		}
		
		
		// Order
		if(_this.hasOwnProperty('order')) {
			if(isArray(_this.order)) {
				
				// All tasks in list
				for(var j = 0; j < _this.order.length; j++) {
					if(o.tasks.hasOwnProperty(_this.order[j])) {
						if(!o.tasks[_this.order[j]].hasOwnProperty('deleted')) {
							
							// Push to order
							o.lists.items[i].order.push(_this.order[j])
							
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
		
		// Synced
		if(_this.hasOwnProperty('synced')) {
			if(_this.synced === 'true') _this.synced = true
			if(typeof _this.synced === 'boolean') {
				o.lists.items[i].synced = _this.synced
			}
		}
	}
	
	// List order. Part II: Removing.
	for(var i = 0; i < lists.order.length; i++) {
		var _this = lists.order[i]
		if(o.lists.items.hasOwnProperty(_this)) {
			if(!o.lists.items[_this].hasOwnProperty('deleted')) {
				o.lists.order.push(_this)
			}
		}
	}
	
	// List order. Part I: Adding.
	for(var i = 0; i < o.lists.items.length; i++) {
		var _this = o.lists.items[i]
		if(!_this.hasOwnProperty('deleted')) {
			var index = o.lists.order.indexOf(i)
			if(index < 0) {
				o.lists.order.push(i)
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
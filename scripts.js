
$(document).ready(function() {

	$.getJSON('json/server.json?n=1', function(data) {
		add(data, 'server');
		server = data;
		cli.storage = server;
		cli.storage.save = function() {};
	});
	$.getJSON('json/comp1.json?n=1', function(data) {
		add(data, 'client1');
		comp1 = data;
	});
	$.getJSON('json/comp2.json?n=1', function(data) {
		add(data, 'client2');
		comp2 = data;
	});


});

function add(obj, column) {
	$('#' + column + ' pre').html(JSON.stringify(obj, null, 4))
}

function clone(input) {
	return JSON.parse(JSON.stringify(input));
}

function get(comp, el) {

	// If computer has never been synced before
	if(comp.prefs.hasOwnProperty('synced')) {

		// Loop through each task
		for(var task in comp.tasks) {
			
			// Does not sync the length key
			if(task != 'length') {

				// Mess with task id's
				comp.tasks[parseInt(task) + server.tasks.length] = clone(comp.tasks[task]);
				delete comp.tasks[task]

			}
		}
	}

	// Loop through each task
	for(var task in comp.tasks) {

		// If task does not exist on the server
		if(!server.tasks.hasOwnProperty(task)) {

			// If task hasn't been deleted
			if(!comp.tasks[task].hasOwnProperty('deleted')) {

				// Add the task to the server
				cli.addTask(comp.tasks[task].content, comp.tasks[task].list);
				server.tasks[task] = clone(comp.tasks[task]);

				// Calculate date
				cli.calc.date(task);

				// Calculate Today etc? - Do later
				cli.today(task).calculate();

			// The task is new, but the client deleted it
			} else {

				// Add the task to the server, but don't touch lists and stuff
				server.tasks[task] = clone(comp.tasks[task]);

			}

		// Task was deleted on computer but not on the server
		} else if(comp.tasks[task].hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

			// We use this to check whether the task was modified AFTER it was deleted
			var deleteTask = true;

			// Loop through each attribute on server
			for(var key in server.tasks[task]) {

				// Check if server task was modified after task was deleted
				if(server.tasks[task].time[key] > comp.tasks[task].deleted) {

					// Since it has been modified after it was deleted, we don't delete the task
					deleteTask = false;

				}
			}

			// If there have been no modifications to the task after it has been deleted
			if(deleteTask) {

				// Delete the task
				cli.deleteTask(task);

				// Get the timestamp
				server.tasks[task] = clone(comp.tasks[task]);

				// Update stuff
				// cli.calc.date(task);
				// cli.today(task).calculate();

			}

		// Task is deleted on the server and the computer
		} else if(comp.tasks[task].hasOwnProperty('deleted') && server.tasks[task].hasOwnProperty('deleted')){

			// Use the latest time stamp
			if(comp.tasks[task].deleted > server.tasks[task].deleted) {

				// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
				server.tasks[task].deleted = comp.tasks[task].deleted;

			}

		} else {

			//Stores the Attrs we'll be needing later
			var changedAttrs = [];

			// Loop through each attribute on computer
			for(var key in comp.tasks[task]) {

				//Don't loop through timestamps
				if (key != 'time') {

					// Check if task was deleted on server or 
					 if (server.tasks[task].hasOwnProperty('deleted')) {

						// Check if task was modified after it was deleted
						if(comp.tasks[task].time[key] > server.tasks[task].deleted) {

							// Update the server with the entire task (including attributes and timestamps)
							server.tasks[task] = comp.tasks[task];

							//Breaks, we only need to do the thing once.
							break;
						}

					// Task has not been deleted
					} else {

						// If the attribute was updated after the server
						if(comp.tasks[task].time[key] > server.tasks[task].time[key]) {


							if (key != 'list') {
								// Update the servers version
								server.tasks[task][key] = comp.tasks[task][key];
							}
							
							// Update the timestamp
							server.tasks[task].time[key] = comp.tasks[task].time[key];

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
					cli.moveTask(task, comp.tasks[task].list)
				}
			}
		}
	}

	// Print to UI
	add(server, 'server');
	add(server, el);

}
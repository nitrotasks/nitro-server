
$(document).ready(function() {

	function loadJSON(data, device) {
		for (var task in data.tasks) {
			if(task != 'length') add(data.tasks[task], task, device);
		}
	}

	$.getJSON('json/server.json?n=1', function(data) {
		loadJSON(data, 'server');
		server = data;
	});
	$.getJSON('json/comp1.json?n=1', function(data) {
		loadJSON(data, 'comp1');
		comp1 = data;
	});
	$.getJSON('json/comp2.json?n=1', function(data) {
		loadJSON(data, 'comp2');
		comp2 = data;
	});


});

function add(task, id, device) {

	// If task is deleted, show greyed out task
	if(task.hasOwnProperty('deleted')) {
		$('#' + device + ' ul').append('<li class="' + id + '" data-deleted="true" data-time="' + task.deleted + '"><span class="content">Deleted</span></li>');

	// Else show task as normal
	} else {
		$('#' + device + ' ul').append('<li class="' + id + '" data-priority="' + task.priority + '" data-time="' + task.time.content + '|' + task.time.notes + '|' + task.time.priority + '"><span class="content">' + task.content + '</span><span class="notes">' + task.notes + '</span></li>');
	}
}

function clone(input) {
	return JSON.parse(JSON.stringify(input));
}

function get(comp, el) {

	// var comp = {};

	// //Gets Tasks from computer
	// $('#' + computer + ' ul').find('li').map(function() {

	// 	// Get timestamps (content | notes | priority)
	// 	var time = $(this).attr('data-time').split('|');

	// 	// Convert strings to integers
	// 	for(var x in time) {
	// 		time[x] = parseInt(time[x]);
	// 	}
		
	// 	if($(this).attr('data-deleted') == 'true') {

	// 		// Task has been deleted!
	// 		comp[$(this).attr('class')] = {
	// 			deleted: time[0]
	// 		}

	// 	} else {

	// 		// Get attributes
	// 		comp[$(this).attr('class')] = {
	// 			content:  {
	// 				value: $(this).find('.content').text(),
	// 				time: time[0]
	// 			},
	// 			notes: {
	// 				value: $(this).find('.notes').text(),
	// 				time: time[1]
	// 			},
	// 			priority: {
	// 				value: $(this).attr('data-priority'),
	// 				time: time[2]
	// 			}
	// 		}
	// 	}
	// });

	// Loop through each task
	for(var task in comp.tasks) {

		// Task was deleted on computer but not on the server
		if(comp.tasks[task].hasOwnProperty('deleted') && !server.tasks[task].hasOwnProperty('deleted')) {

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

				// Clone computer's task to server
				server.tasks[task] = clone(comp.tasks[task]);

			}

		// Task is deleted on the server and the computer
		} else if(comp.tasks[task].hasOwnProperty('deleted') && server.tasks[task].hasOwnProperty('deleted')){

			// Use the latest time stamp
			if(comp.tasks[task].deleted > server.tasks[task].deleted) {

				// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
				server.tasks[task].deleted = comp.tasks[task].deleted;

			}

		} else {

			// Loop through each attribute on computer
			for(var key in comp.tasks[task]) {

				//Stores the Attrs we'll be needing later
				var changedAttrs = [];

				//Don't loop through timestamps
				if (key != 'time') {

					// Check if task was deleted on server
					 if (server.tasks[task].hasOwnProperty('deleted')) {

						// Check if task was modified after it was deleted
						if(comp.tasks[task].time[key] > server.tasks[task].deleted) {

							// Update the server with the entire task (including attributes and timestamps)
							server.tasks[task] = comp.tasks[task];

						}

					// Task has not been deleted
					} else {

						// If the attribute was updated after the server
						if(comp.tasks[task].time[key] > server.tasks[task].time[key]) {

							// Update the servers version
							server.tasks[task][key] = comp.tasks[task][key];

							// Update the timestamp
							server.tasks[task].time[key] = comp.tasks[task].time[key];

							//Adds the changed Attr to the array
							changedAttrs.push(key);
						}
					}

					if (changedAttrs.length > 0) {
						alert(changedAttrs)
					}
					
				}
			}
		}
	}

	// Print to UI
	$('#server ul').html('');
	$('#' + el + ' ul').html('');
	for(var task in server.tasks) {
		if(task != 'length') add(server.tasks[task], task, 'server');
		if(task != 'length') add(server.tasks[task], task, el)
	}

}
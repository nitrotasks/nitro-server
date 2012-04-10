server = {
	1: {
		content: { value: "The first task", time: 0 },
		notes: { value:"", time: 0 },
		priority: { value:"none", time: 0 }
	},
	2: {
		content: { value: "The second task", time: 0 },
		notes: { value:"", time: 0 },
		priority: { value:"none", time: 0 }
	},
	3: {
		content: { value: "The third task", time: 0 },
		notes: { value:"", time: 0 },
		priority: { value:"none", time: 0 }
	}
}

// Real legit Nitro database


$(document).ready(function() {

	for (var key in server) {
		add(server[key], key, 'server');
	}

});

function add(task, id, device) {

	// If task is deleted, show greyed out task
	if(task.hasOwnProperty('deleted')) {
		$('#' + device + ' ul').append('<li class="' + id + '" data-deleted="true" data-time="' + task.deleted + '"><span class="content">Deleted</span></li>');

	// Else show task as normal
	} else {
		$('#' + device + ' ul').append('<li class="' + id + '" data-priority="' + task.priority.value + '" data-time="' + task.content.time + '|' + task.notes.time + '|' + task.priority.time + '"><span class="content">' + task.content.value + '</span><span class="notes">' + task.notes.value + '</span></li>');
	}
}

function clone(input) {
	return JSON.parse(JSON.stringify(input));
}

function get(computer) {

	var comp = {};

	//Gets Tasks from computer
	$('#' + computer + ' ul').find('li').map(function() {

		// Get timestamps (content | notes | priority)
		var time = $(this).attr('data-time').split('|');

		// Convert strings to integers
		for(var x in time) {
			time[x] = parseInt(time[x]);
		}
		
		if($(this).attr('data-deleted') == 'true') {

			// Task has been deleted!
			comp[$(this).attr('class')] = {
				deleted: time[0]
			}

		} else {

			// Get attributes
			comp[$(this).attr('class')] = {
				content:  {
					value: $(this).find('.content').text(),
					time: time[0]
				},
				notes: {
					value: $(this).find('.notes').text(),
					time: time[1]
				},
				priority: {
					value: $(this).attr('data-priority'),
					time: time[2]
				}
			}
		}
	});

	// Loop through each task
	for(var task in comp) {

		// Task was deleted on computer but not on the server
		if(comp[task].hasOwnProperty('deleted') && !server[task].hasOwnProperty('deleted')) {

			// We use this to check whether the task was modified AFTER it was deleted
			var deleteTask = true;

			// Loop through each attribute on server
			for(var key in server[task]) {

				// Check if server task was modified after task was deleted
				if(server[task][key].time > comp[task].deleted) {

					// Since it has been modified after it was deleted, we don't delete the task
					deleteTask = false;

				}
			}

			// If there have been no modifications to the task after it has been deleted
			if(deleteTask) {

				// Clone computer's task to server
				server[task] = clone(comp[task]);

			}

		// Task is deleted on the server and the computer
		} else if(comp[task].hasOwnProperty('deleted') && server[task].hasOwnProperty('deleted')){

			// Use the latest time stamp
			if(comp[task].deleted > server[task].deleted) {

				// If the task was deleted on a computer after it was deleted on the server, then update the time stamp
				server[task].deleted = comp[task].deleted;

			}

		} else {

			// Loop through each attribute on computer
			for(var key in comp[task]) {

				// Check if task was deleted on server
				 if (server[task].hasOwnProperty('deleted')) {

					// Check if task was modified after it was deleted
					if(comp[task][key].time > server[task].deleted) {

						// Update the server with the non-deleted version
						server[task] = clone(comp[task]);

					}

				// Task has not been deleted
				} else {

					// If the attribute was updated after the server
					if(comp[task][key].time > server[task][key].time) {

						// Update the servers version
						server[task][key] = clone(comp[task][key]);

					}
				}		
			}
		}
	}

	// Print to UI
	$('#server ul').html('');
	$('#' + computer + ' ul').html('');
	for(var task in server) {
		add(server[task], task, 'server');
		add(server[task], task, computer)
	}

}
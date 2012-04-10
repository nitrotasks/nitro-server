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

$(document).ready(function() {

	for (var key in server) {
		add(server[key], key, 'server');
	}

});

function add(task, id, device) {
	$('#' + device + ' ul').append('<li class="' + id + '" data-priority="' + task.priority.value + '" data-time="' + task.content.time + '|' + task.notes.time + '|' + task.priority.time + '"><span class="content">' + task.content.value + '</span><span class="notes">' + task.notes.value + '</span></li>');
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

		// Create computer
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
		console.log(comp);
	});

	for(var task in comp) {
		for(var key in comp[task]) {
			if(comp[task][key].time > server[task][key].time) {
				server[task][key] = clone(comp[task][key]);
			}
		}
	}

	$('#server ul').html('');
	$('#' + computer + ' ul').html('');
	for(var task in server) {
		add(server[task], task, 'server');
		add(server[task], task, computer)
	}

}
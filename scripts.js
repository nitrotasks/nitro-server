/*$(document).ready(function() {

	var id = 0;
	if($.jStorage.get('tasks')) {
		for (var key in $.jStorage.get('tasks')) {
			add($.jStorage.get('tasks')[key], key);
		}
	}

	$('.add').click(function() {
		add($('input').val());
		$('input').val('');
		save();
	});

	function add(value, _id) {
		if(!_id) _id = id;
		$('.main').append('<li class="' + _id + '">' + value + '</li>');
		id++;
	}

	function save() {
		var tasks = {};
		$('.main li').each(function(index, key) {
			tasks[$(key).attr('class')] = $(key).html();
		});
		$.jStorage.set('tasks', tasks);
	}
});*/

server = {
	1: {

	},
	2: {
		1: "Just a task"
	},
	3: {
		1: "Task with ID1",
	},
	4: {
		1: "Task with ID1",
		2: "Task with ID2",
	},
	5: {

	}
};

function get(computer) {

	comp = new Object()

	serverRev = parseInt($('#server .rev').text());
	compRev = parseInt($('#' + computer + ' .rev').text());
	compChanged = $('#' + computer + ' .rev').attr('data-changed');

	console.log(serverRev);

	//Gets Tasks from each place
	$('#server ul').children().map(function() {
		server[serverRev][$(this).attr('class')] = $(this).text()
	});

	$('#' + computer + ' ul').children().map(function() {
		comp[$(this).attr('class')] = $(this).text()
	});

	//Makes sure there's been a change
	if (compChanged == 'true') {
		//If the server is on the same rev as one computer, we can overwrite =)
		if (serverRev == compRev) {
			//Sets Data
			server[serverRev] = comp;

			//Replaces Server List
			$('#server ul').html('');
			for (var key in server[serverRev]) {
				$('#server ul').append('<li class="' + key + '">' + server[serverRev][key] + '</li>');
			}

			//We go up a rev
			serverRev++;
			compRev++;
			$('#server .rev').text(serverRev);
			$('#' + computer + ' .rev').text(compRev);
			server[serverRev] = {};

			$('#' + computer + ' .rev').attr('data-changed', 'false');
		} else {

			//The data has been conflicted
			alert('OH SNAP CONFLICTS!');
		}
	} else {
		//No Change? Great. We can bypass all this =)

		//Only push data if on diffrent revs
		if (serverRev != compRev) {

			comp = server[serverRev];

			//Replaces Comp list
			$('#' + computer + ' ul').html('');
			for (var key in comp) {
				$('#' + computer + ' ul').append('<li class="' + key + '">' + comp[key] + '</li>');
			}

			//Changes Rev to latest
			$('#' + computer + ' .rev').text(serverRev);
		}
	}

	/*//We're taking the stuff off comp1 that's on the server
	difference = comp1;

	for (var key in server) {
		//If it's the same on both the server & comp1, delete from difference
		if (server[key] == comp1[key]) {
			delete difference[key]
		}
	}

	return difference;*/
}
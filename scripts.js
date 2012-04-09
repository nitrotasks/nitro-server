server = {
	index: 5,
	1: {
		// nothing
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
		1: "Task with ID1",
		2: "Task with ID2",
		3: "Task with ID3"
	}
};

$(document).ready(function() {

	for (var key in server[server.index]) {
		add(server[server.index][key], key);
	}
	$('#server .rev').text(server.index);

	function add(value, id) {
		$('#server ul').append('<li class="' + id + '">' + value + '</li>');
	}

});

function get(computer) {

	comp = new Object()

	compRev = parseInt($('#' + computer + ' .rev').text());
	compChanged = $('#' + computer + ' .rev').attr('data-changed');

	//Gets Tasks from computer
	$('#' + computer + ' ul').children().map(function() {
		comp[$(this).attr('class')] = $(this).text()
	});

	//Makes sure there's been a change
	if (compChanged == 'true') {
		//If the server is on the same rev as one computer, we can overwrite =)
		if (server.index == compRev) {

			//We go up a rev
			server.index++;
			compRev++;

			//Sets Data
			server[server.index] = comp;

			//Replaces Server List
			$('#server ul').html('');
			for (var key in server[server.index]) {
				$('#server ul').append('<li class="' + key + '">' + server[server.index][key] + '</li>');
			}

			// Display revisions
			$('#server .rev').text(server.index);
			$('#' + computer + ' .rev').text(compRev);

			$('#' + computer + ' .rev').attr('data-changed', 'false');
		} else {

			difference = comp;

			for (var key in server[compRev]) {
				//If it's the same on both the server & comp1, delete from difference
				if (server[compRev][key] == comp[key]) {
					delete difference[key]
				}
			}

			//Finds length of server obj
			var count = 0;
			for (var i in server[server.index]) {
			    if (server[server.index].hasOwnProperty(i)) {
			        count++;
			    }
			}

			var newRev = server[server.index];
			for (var i in difference) {
				count++;
				newRev[count] = difference[i]
			}

			//Merges newrev with server
			server.index++;
			server[server.index] = newRev;

			//Changes UI
			//Replaces Server List
			$('#server ul').html('');
			for (var key in server[server.index]) {
				$('#server ul').append('<li class="' + key + '">' + server[server.index][key] + '</li>');
			}

			// Display revisions
			$('#server .rev').text(server.index);

			//Replaces Comp list
			$('#' + computer + ' ul').html('');
			for (var key in server[server.index]) {
				$('#' + computer + ' ul').append('<li class="' + key + '">' + server[server.index][key] + '</li>');
			}

			$('#' + computer + ' .rev').text(server.index);
			$('#' + computer + ' .rev').attr('data-changed', 'false');

			//The data has been conflicted
			alert('OH SNAP CONFLICTS!');
		}
	} else {
		//No Change? Great. We can bypass all this =)

		//Only push data if on diffrent revs
		if (server.index != compRev) {

			comp = server[server.index];

			//Replaces Comp list
			$('#' + computer + ' ul').html('');
			for (var key in comp) {
				$('#' + computer + ' ul').append('<li class="' + key + '">' + comp[key] + '</li>');
			}

			//Changes Rev to latest
			$('#' + computer + ' .rev').text(server.index);
		}
	}
	
}
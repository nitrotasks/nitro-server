server = {
	index: 5,
	5: {
		1: {"content":"The first task","notes":""},
		2: {"content":"The second task","notes":""},
		3: {"content":"The third task","notes":""}
	}
};

$(document).ready(function() {

	for (var key in server[server.index]) {
		add(server[server.index][key], key, 'server');
	}
	$('#server .rev').text(server.index);

});

function add(task, id, device) {
	$('#' + device + ' ul').append('<li class="' + id + '"><span class="content">' + task.content + '</span><span class="notes">' + task.notes + '</span></li>');
}

function get(computer) {

	// Create computer
	comp = new Object()

	// Get the computers revision number and whether it's data has been changed
	compRev = parseInt($('#' + computer + ' .rev').text());
	compChanged = $('#' + computer + ' .rev').data('changed');

	//Gets Tasks from computer
	$('#' + computer + ' ul').find('li').map(function() {
		comp[$(this).attr('class')] = {};
		comp[$(this).attr('class')]['content'] = $(this).find('.content').text();
		comp[$(this).attr('class')]['notes'] = $(this).find('.notes').text();
	});

	//Makes sure there's been a change
	if (compChanged == true) {

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
				add(server[server.index][key], key, 'server');
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
				add(server[server.index][key], key, 'server');
			}

			// Display revisions
			$('#server .rev').text(server.index);

			//Replaces Comp list
			$('#' + computer + ' ul').html('');
			for (var key in server[server.index]) {
				add(server[server.index][key], key, computer);
			}

			$('#' + computer + ' .rev').text(server.index);
			$('#' + computer + ' .rev').attr('data-changed', 'false');

		}
	} else {
		//No Change? Great. We can bypass all this =)

		//Only push data if on diffrent revs
		if (server.index != compRev) {

			comp = server[server.index];

			//Replaces Comp list
			$('#' + computer + ' ul').html('');
			for (var key in comp) {
				add(comp[key], key, computer);
			}

			//Changes Rev to latest
			$('#' + computer + ' .rev').text(server.index);
		}
	}
	
}
server = {
	index: 5,
	4: {
		1: {"content":"The first task","notes":""},
		2: {"content":"The second task","notes":""}
	},
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

function clone(input) {
	return JSON.parse(JSON.stringify(input));
}

function get(computer) {

	// Create computer
	comp = new Object()

	// Get the computers revision number and whether it's data has been changed
	compRev = parseInt($('#' + computer + ' .rev').text());
	compChanged = $('#' + computer + ' .rev').attr('data-changed');

	//Gets Tasks from computer
	$('#' + computer + ' ul').find('li').map(function() {
		comp[$(this).attr('class')] = {};
		comp[$(this).attr('class')]['content'] = $(this).find('.content').text();
		comp[$(this).attr('class')]['notes'] = $(this).find('.notes').text();
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
				add(server[server.index][key], key, 'server');
			}

			// Display revisions
			$('#server .rev').text(server.index);
			$('#' + computer + ' .rev').text(compRev);

			$('#' + computer + ' .rev').attr('data-changed', 'false');

		} else {

			/* New Code */

			// Create a difference object where data will be deleted from
			newRev = clone(server[server.index]);
			difference = clone(comp);
			modified = [];

			// For each key on the server, it has to check against the new data
			for (var key in server[compRev]) {
				if (JSON.stringify(server[compRev][key]) == JSON.stringify(comp[key])) {
					//Deletes if Data is identical
					delete difference[key];
				} else {
					//The object exists on the server but has been modified
					modified.push(key);
					delete difference[key];
				}
			}

			/* Block of code that modification detection will go in */

			// Loops through modifed shit
			for(var key=0; key<modified.length; key++) {

				// Check if key exists on the server
				if(comp.hasOwnProperty(modified[key]) && server[server.index].hasOwnProperty(modified[key])) {

					// Checks if content is the same on both revs
					if (server[compRev][modified[key]].content == server[server.index][modified[key]].content) {
						
						// Content is the same on both revs so we can use the new data
						newRev[modified[key]].content = comp[modified[key]].content

					// Conflict! Ask user what to do...
					} else if(confirm('Do you want to keep "' + comp[modified[key]].content + '"?')) {
						// Replace current with user's choice
						newRev[modified[key]].content = comp[modified[key]].content
					}

				} else {
					// Key is deleted

					newRev[modified[key]] = {content: '', notes: ''};

					if(server[server.index].hasOwnProperty(modified[key])) {
						newRev[modified[key]].content = server[server.index][modified[key]].content;
					} else {
						newRev[modified[key]].content = comp[modified[key]].content
					}
				}
			}


			//Finds length of server obj
			var count = 0;
			for (var i in server[server.index]) {
			    if (server[server.index].hasOwnProperty(i)) {
			        count++;
			    }
			}

			//Joins server data to difference
			for (var i in difference) {
				count++;
				newRev[count] = difference[i]
			}

			//Merges newrev with server
			server.index++;
			server[server.index] = newRev;

			/**** PRINT TO UI ****/

			//Replaces Server and Computer List
			$('#server ul').html('');
			$('#' + computer + ' ul').html('');
			for (var key in server[server.index]) {
				add(server[server.index][key], key, 'server');
			}
			for (var key in server[server.index]) {
				add(server[server.index][key], key, computer);
			}

			// Display revisions
			$('#server .rev').text(server.index);
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
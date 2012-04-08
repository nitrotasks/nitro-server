function get(computer) {
	server = new Object()
	comp = new Object()

	serverRev = $('#server .rev').text()
	compRev = $('#' + computer + ' .rev').text()
	compChanged = $('#' + computer + ' .rev').attr('data-changed');

	//Gets Tasks from each place
	$('#server ul').children().map(function() {
		server[$(this).attr('class')] = $(this).text()
	});

	$('#' + computer + ' ul').children().map(function() {
		comp[$(this).attr('class')] = $(this).text()
	});

	//Makes sure there's been a change
	if (compChanged == 'true') {
		//If the server is on the same rev as one computer, we can overwrite =)
		if (serverRev == compRev) {
			//Sets Data
			server = comp;

			//Replaces Server List
			$('#server ul').html('');
			for (var key in server) {
				$('#server ul').append('<li>' + server[key] + '</li>');
			}

			//We go up a rev
			$('#server .rev').text(parseInt(serverRev)+1)
			$('#' + computer + ' .rev').text(parseInt(compRev)+1)

			$('#' + computer + ' .rev').attr('data-changed', 'false');
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
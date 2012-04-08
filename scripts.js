$(document).ready(function() {

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
});

function get() {
	server = new Object()
	comp1 = new Object()

	$('#server ul').children().map(function() {
		server[$(this).attr('class')] = $(this).text()
	});

	$('#comp1 ul').children().map(function() {
		comp1[$(this).attr('class')] = $(this).text()
	});

	//We're taking the stuff off comp1 that's on the server
	difference = comp1;

	for (var key in server) {
		//If it's the same on both the server & comp1, delete from difference
		if (server[key] == comp1[key]) {
			delete difference[key]
		}
	}

	return difference;
}
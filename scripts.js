$(document).ready(function() {

	var id = 0;
	if($.jStorage.get('tasks')) {
		console.log($.jStorage.get('tasks'));
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
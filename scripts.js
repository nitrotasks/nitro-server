$(document).ready(function() {
	var id = 0;
	$('.add').click(function() {
		$('.main').append('<li class="' + id + '">' + $('input').val() + '</li>');
		$('input').val('');

		save();
	});

	function save() {
		var tasks = {};
		$('.main li').each(function(index, key) {
			tasks[index] = $(key).html();
		});
		console.log(tasks);
	}
});
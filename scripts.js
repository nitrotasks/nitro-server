$(document).ready(function() {
	var id = 0;
	$('.add').click(function() {
		$('.main').append('<li class="' + id + '">' + $('input').val() + '</li>');
		$('input').val('');
	});
});
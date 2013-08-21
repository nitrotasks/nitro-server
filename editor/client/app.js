
// require('jquery');

$(function () {

  var SYNTAX_ERROR = 'Error! Invalid JSON';

  var el = {
    form: $('form'),
    uid: $('.uid'),
    editor: $('.editor'),
    check: $('.check'),
    save: $('.save')
  };

  var uid = 0;

  // Read from database
  function read (id) {
    return $.ajax({
      method: 'get',
      url: '/read/' + id
    });
  }

  // Write to database
  function write (user, id) {
    return $.ajax({
      method: 'post',
      url: '/update/' + id,
      data: {
        user: user
      }
    });
  }

  function display (obj) {
    var text = JSON.stringify(obj, null, 2);
    el.editor.val(text);
  }

  // Check if text is valid JSON
  function check (text) {
    try {
      JSON.parse(text);
    } catch (e) {
      return false;
    }
    return true;
  }

  // Bind events
  el.form.on('submit', function (e) {
    e.preventDefault();
    uid = el.uid.val();
    read(uid).then(function (user, state) {
      if (state === 'success') {
        display(user);
      }
    });
  });

  el.check.on('click', function () {
    var text = el.editor.val();
    if (check(text)) {
      alert(':)');
    } else {
      alert(SYNTAX_ERROR);
    }
  });

  el.save.on('click', function  () {
    var text = el.editor.val();
    if (check(text)) {
      write(text, uid).then(function () {
        console.log(arguments);
      });
    } else {
      alert(SYNTAX_ERROR);
    }
  });

});

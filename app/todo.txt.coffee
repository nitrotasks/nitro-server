User = require("./storage")
Q = require("q")

generate = (uid, listId) ->

  deferred = Q.defer()

  User.get(uid)
    .then (user) ->
      tasks = user.data("Task")
      lists = user.data("List")

      # Try to get tasks in list, else just get all tasks
      list = lists[listId]?.tasks or Object.keys(tasks)

      if user.has_pro is 0

        text = []
        priorityArray = ["", "(A) ", "(B) ", "(C) "]

        for id, task of tasks
          continue if task.completed or not (task.id in list)
          text[text.length] = priorityArray[task.priority]
          text[text.length] = task.name
          text[text.length] = " due:" + new Date(task.date).toISOString().substr(0, 10) unless task.date is ""
          text[text.length] = " +" +lists[task.list].name
          text[text.length] = "\n"

        deferred.resolve text.join("")

      else deferred.resolve "You'll need a Nitro Pro Account to generate todo.txt.\nLearn more at <a href=\"http://nitrotasks.com\">the nitrotasks website.</a>"

    .fail ->
      deferred.resolve "Couldn't find user"

  return deferred.promise

module.exports = generate

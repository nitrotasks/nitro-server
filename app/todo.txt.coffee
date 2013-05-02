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

      if user.pro is 1

        text = []
        priorityArray = ["", "(A) ", "(B) ", "(C) "]

        for id, task of tasks
          continue if task.completed or task.deleted or not (task.id in list)
          console.log(task)
          if task.date?.length?
            date = new Date(task.date).toDateString()
          else
            date = ""
          text[text.length] = priorityArray[task.priority]
          text[text.length] = task.name
          text[text.length] = date
          text[text.length] = " +" +lists[task.list]?.name
          text[text.length] = "\n"

        deferred.resolve [text.join(""), user]

      else
        deferred.reject "err_not_pro"

    .fail (err) ->
      console.error(err)
      deferred.reject "err_no_user"

  return deferred.promise

module.exports = generate

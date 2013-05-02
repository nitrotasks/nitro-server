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
        priorityArray = ["", "1BC1F5", "9DD071", "E15556"]

        text[text.length] = """
          <h2>#{ list.name or "All Tasks" }</h2>
          <table rules="all" style="border: 1px solid #dbdbdb;">
        """

        for id, task of tasks
          continue if task.completed or not (task.id in list)

          priority = "width: 4px; background: #" + priorityArray[task.priority]
          date = if task.date?.length? then new Date(task.date).toDateString() else ""

          text[text.length] = """
            <tr style="height: 30px;">
              <td style="#{priority}"></td>
              <td style="width: 15px"></td>
              <td style="width: 0px"></td>
              <td style="padding: 0 10px;">#{ task.name }</td>
              <td style="padding: 0 10px;">#{ date }</td>
            </tr>
          """

        text[text.length] = """
          </table>
        """

        deferred.resolve [text.join(""), user]

      else
        deferred.reject "err_not_pro"

    .fail ->
      deferred.reject "err_no_user"

  return deferred.promise

module.exports = generate

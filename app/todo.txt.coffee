# Generate Stuff

generate = (tasks, pro) ->

  if pro

    text = []

    priorityArray = ["", "(A) ", "(B) ", "(C) "]

    for task in tasks
      text[text.length] = priorityArray[task.priority]
      text[text.length] = task.name
      text[text.length] = " due:" + new Date(task.date).toISOString().substr(0, 10) unless task.date is ""
      text[text.length] = " +" + List.find(task.list).name + "\n"

    return text.join("")

  else return "You'll need a Nitro Pro Account to generate todo.txt\nLearn more at <http://nitrotasks.com>"

module.exports = generate

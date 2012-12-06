socket = io.connect('http://localhost:8080')

window.storage = storage = {}

socket.emit 'requestData', 'username'
socket.on 'sendData', (data) ->
  storage.Settings = data.Settings
  storage.List = data.List
  storage.Task = data.Task

window.addTask = (id, name, list="inbox") ->
  index = storage.Task.push
    name: name,
    completed: false,
    priority: 1,
    list: list,
    id: id
  socket.emit 'create', ["task", storage.Task[index-1]]

window.updateTask = (id, attr, val) ->
  for task in storage.Task
    if task.id is id
      break
  task[attr] = val
  socket.emit 'update', ["task", id, attr, val]

window.destroyTask = (id) ->
  for task, index in storage.Task
    if task.id is id then break
  storage.Task.splice(index, 1)
  socket.emit 'destroy', ["task", id]

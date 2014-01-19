###
           ___  __   __      __            __
    |\ | |  |  |__) /  \    /__` \ / |\ | /  `
    | \| |  |  |  \ \__/    .__/  |  | \| \__,

    ------------------------------------------

    This is the sync code. It's a wee bit crazy.

###


Q       = require 'kew'
Log     = require '../utils/log'
Time    = require '../utils/time'

log      = Log 'Sync', 'cyan'
logEvent = Log 'Sync Event', 'yellow'

# CONSTANTS

LIST = 'list'
PREF = 'pref'
TASK = 'task'
INBOX = 'inbox'

SERVER_ID = 's'
CLIENT_ID = 'c'


# Does all the useful stuff
class Sync

  constructor: (@user) ->
    @time = new Time(@user)


  ###
   * Create a new ID for a model
   *
   * - classname (string)
   * > int
  ###

  createId: (classname) ->
    id = @user.incrIndex classname
    return SERVER_ID + (id - 1)


  #####################################
  #    __   __   ___      ___  ___    #
  #   /  ` |__) |__   /\   |  |__     #
  #   \__, |  \ |___ /~~\  |  |___    #
  #                                   #
  #####################################



  task_create: (model, timestamp) =>

    unless @user.hasModel(LIST, model.listId)
      log 'Trying to add a task to a list that doesn\'t exist'
      return null

    id = @createId TASK
    model.id = id

    @taskAdd id, model.listId

    @user.setModel TASK, id, model

    timestamp ?= Date.now()
    @time.set TASK, id, '*', timestamp

    log '[task] Created', id, model.name

    return id

  list_create: (model, timestamp) =>

    if model.id is INBOX
      id = INBOX
      if @user.hasModel(LIST, INBOX) then return null
      log '[list] [create] made inbox'
    else
      id = @createId LIST
      model.id = id

    model.tasks = []

    @user.setModel LIST, id, model

    timestamp ?= Date.now()
    @time.set LIST, id, '*', timestamp

    log '[list] Created', id, model.name

    return id



  ####################################
  #         __   __       ___  ___   #
  #   |  | |__) |  \  /\   |  |__    #
  #   \__/ |    |__/ /~~\  |  |___   #
  #                                  #
  ####################################

  task_update: (changes, timestamps) =>

    # id is a required field
    id = changes.id
    delete changes.id

    # Check model exists on server
    unless @user.hasModel(TASK, id)
      log '[task] [update] could not find', id
      return null

    if @user.findModel(TASK, id).deleted
      log '[task] [update] already deleted', id
      return null

    # Set timestamp
    if timestamps
      for attr, time of timestamps
        old = @time.get TASK, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]
      if Object.keys(changes).length is 0
        log '[task] [update] old event', id
        return null
    else
      timestamps = {}
      now = Date.now()
      for key of changes
        timestamps[key] = now

    @time.set TASK, id, timestamps

    # If task has changed list
    if changes.listId?
      oldTask = @user.findModel TASK, id
      if oldTask.listId isnt changes.listId
        @taskMove id, oldTask.listId, changes.listId

    # Save to server
    model = @user.updateModel TASK, id, changes
    log '[task] updated', id, model.name

    changes.id = id
    return changes

  list_update: (changes, timestamps) =>

    # id is a required field
    id = changes.id
    delete changes.id

    # Check model exists on server
    unless @user.hasModel(LIST, id)
      log '[list] [update] could not find', id
      return null

    if @user.findModel(LIST, id).deleted
      log '[list] [update] already deleted', id
      return null

    # Set timestamp
    if timestamps
      for attr, time of timestamps
        old = @time.get LIST, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]
      if Object.keys(changes).length is 0
        log '[list] [update] old event', id
        return null
    else
      timestamps = {}
      now = Date.now()
      for key of changes
        timestamps[key] = now

    if changes.tasks
      console.log 'WE CAN NOT HANDLE THIS YET!!!!'
      delete changes.tasks
      delete timestamps.tasks

    @time.set LIST, id, timestamps

    # Save to server
    model = @user.updateModel LIST, id, changes
    log '[list] updated', id

    changes.id = id
    return changes

  pref_update: (changes, timestamps) =>

    # Pref id is always s0
    id = SERVER_ID + '0'

    # Set timestamp
    if timestamps
      for attr, time of timestamps
        old = @time.get PREF, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]
      if Object.keys(changes).length is 0
        log '[pref] [update] old event', id
        return null
    else
      timestamps = {}
      now = Date.now()
      for key of changes
        timestamps[key] = now

    @time.set PREF, id, timestamps

    # Save to server
    model = @user.updateModel PREF, id, changes
    log '[pref] updated', changes

    return changes



  ########################################
  #    __   ___  __  ___  __   __        #
  #   |  \ |__  /__`  |  |__) /  \ \ /   #
  #   |__/ |___ .__/  |  |  \ \__/  |    #
  #                                      #
  ########################################

  task_destroy: (id, timestamp) =>

   if not @user.hasModel(TASK, id)
     log '[task] [destroy] could not find:', id
     return null

    model = @user.findModel TASK, id

    if model.deleted
      log '[task] [destroy] already deleted:', id
      return null

    # Check that the model hasn't been updated after this event
    timestamp ?= Date.now()
    unless @time.check TASK, id, timestamp
      return null

    # Remove from list
    @taskRemove id, model.listId

    # Replace task with deleted template
    @user.setModel TASK, id,
      id: id
      deleted: true

    # Set timestamp
    @time.set TASK, id, 'deleted', timestamp
    log '[task] destroyed', id

    return true

  list_destroy: (id, timestamp) =>

   if not @user.hasModel(LIST, id)
     log '[list] [destroy] could not find:', id
     return null

    model = @user.findModel LIST, id

    if model.deleted
      log '[list] [destroy] already deleted:', id
      return null

    # Check that the model hasn't been updated after this event
    timestamp ?= Date.now()
    unless @time.check LIST, id, timestamp
      return null

    # Destroy all tasks within that list
    for taskId, i in model.tasks by -1
      @task_destroy taskId, timestamp

    # Replace task with deleted template
    @user.setModel LIST, id,
      id: id
      deleted: yes

    # Set timestamp
    @time.set LIST, id, 'deleted', timestamp
    log '[list] [destroy] deleted:', id

    return true

# -----------------------------------------------------------------------------
# Useful Task Management Methods
# -----------------------------------------------------------------------------


  # Add a task to a list
  taskAdd: (taskId, listId) ->
    tasks = @user.findModel(LIST, listId).tasks
    return false unless tasks
    if tasks.indexOf(taskId) < 0
      tasks.push taskId
      @user.save LIST

  # Remove a task from a list
  taskRemove: (taskId, listId) ->
    tasks = @user.findModel(LIST, listId).tasks
    return false unless tasks
    index = tasks.indexOf taskId
    if index > -1
      tasks.splice index, 1
      @user.save LIST

  # Move a task from list to another
  taskMove: (taskId, oldListId, newListId) ->
    @taskAdd taskId, newListId
    @taskRemove taskId, oldListId

  # Replace a task ID
  taskUpdateId: (oldId, newId, listId) ->
    tasks = @user.findModel(LIST, listId).tasks
    index = tasks.indexOf oldId
    if index > -1
      tasks.spice index, 1, newId
      @user.save LIST

module.exports = Sync

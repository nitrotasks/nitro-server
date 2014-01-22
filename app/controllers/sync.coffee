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

SERVER_PREFIX = 's'
PREF_ID = SERVER_PREFIX + '0'


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
    return SERVER_PREFIX + (id - 1)


  #####################################
  #    __   __   ___      ___  ___    #
  #   /  ` |__) |__   /\   |  |__     #
  #   \__, |  \ |___ /~~\  |  |___    #
  #                                   #
  #####################################



  task_create: (model, timestamp) =>

    unless @user.checkModel(LIST, model.listId)
      log 'Trying to add a task to a list that doesn\'t exist'
      return null

    list = @user.findModel(LIST, model.listId)

    id = @createId TASK
    model.id = id

    @taskAdd id, list

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

  generic_update: (changes, timestamps) =>

    # Handles generic code for updating a model

  task_update: (changes, timestamps) =>

    # id is a required field
    id = changes.id
    delete changes.id

    # Check model exists on server
    unless @user.checkModel(TASK, id)
      log '[task] [update] could not find', id
      return null

    # Check listId
    if changes.listId?
      unless @user.checkModel(LIST, changes.listId)
        console.log '[task] [update] could not find list', id
        return null
      oldTask = @user.findModel TASK, id
      if oldTask.listId isnt changes.listId
        @taskMove id, oldTask.listId, changes.listId

    # Set timestamp
    if timestamps
      for attr, time of timestamps
        old = @time.get TASK, id, attr
        if old > time
          log '[task] [update] old prop', attr,
            time: time
            old: old
            diff: old - time
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

    # Save to server
    @time.set TASK, id, timestamps
    @user.updateModel TASK, id, changes

    log '[task] updated', id

    changes.id = id
    return changes

  list_update: (changes, timestamps) =>

    # id is a required field
    id = changes.id
    delete changes.id

    # Check model exists on server
    unless @user.checkModel(LIST, id)
      log '[list] [update] could not find', id
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
    id = PREF_ID

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

    unless @user.checkModel(TASK, id)
     log '[task] [destroy] could not find:', id
     return null

    model = @user.findModel TASK, id

    # Check that the model hasn't been updated after this event
    timestamp ?= Date.now()
    unless @time.check TASK, id, timestamp
      return null

    # Remove from list
    list = @user.findModel(LIST, model.listId)
    if list.tasks?
      @taskRemove id, model.listId

    # Replace task with deleted template
    @user.setModel TASK, id,
      id: id
      deleted: true

    # Set timestamp
    @time.set TASK, id, 'deleted', timestamp
    log '[task] [destroy] deleted', id

    return true

  list_destroy: (id, timestamp) =>

    console.log 'attempting to destroy list', id

    unless @user.checkModel(LIST, id)
      log '[list] [destroy] could not find:', id
      return null

    model = @user.findModel(LIST, id)

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
  taskAdd: (taskId, list) ->
    tasks = list.tasks
    return false unless tasks
    if tasks.indexOf(taskId) < 0
      tasks.push taskId
      @user.save LIST

  # Remove a task from a list
  taskRemove: (taskId, list) ->
    tasks = list.tasks
    return false unless tasks
    index = tasks.indexOf taskId
    if index >= 0
      tasks.splice index, 1
      @user.save LIST

  # Move a task from list to another
  taskMove: (taskId, oldListId, newListId) ->
    list = @user.findModel(LIST, newListId)
    @taskAdd taskId, list
    list = @user.findModel(LIST, oldListId)
    @taskRemove taskId, list

  # Replace a task ID
  taskUpdateId: (oldId, newId, listId) ->
    tasks = @user.findModel(LIST, listId).tasks
    index = tasks.indexOf oldId
    if index >= 0
      tasks.spice index, 1, newId
      @user.save LIST

module.exports = Sync

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


  # Create a new model
  create: (classname, model, timestamp) =>

    # TODO: Get prefs to sync
    if classname is PREF
      id = 1

    # Inbox list is special
    else if classname is LIST and model.id is INBOX
      id = model.id
      if @hasModel(LIST, INBOX) then return

    # Assign server id
    else
      id = model.id = @createId classname

    # Add task to list
    if classname is TASK
      listId = model.list
      @taskAdd id, listId

    # Make sure model.tasks exists
    else if classname is LIST
      model.tasks ?= []

    # Add item to server
    @user.setModel(classname, id, model)

    # Set timestamp
    timestamp ?= Date.now()
    @time.set classname, id, '*', timestamp
    log "Created #{ classname }: #{ model.name }"

    return id



  ####################################
  #         __   __       ___  ___   #
  #   |  | |__) |  \  /\   |  |__    #
  #   \__/ |    |__/ /~~\  |  |___   #
  #                                  #
  ####################################

  # Update existing model
  update: (classname, changes, timestamps) =>

    id = changes.id

    # Check model exists on server
    unless classname is 'pref' or @user.hasModel(classname, id)
      log "#{classname} doesn't exist on server"
      return false

    # Set timestamp
    if timestamps
      for attr, time of timestamps
        old = @time.get classname, id, attr
        if old > time
          delete timestamps[attr]
          delete changes[attr]
    else
      timestamps = {}
      now = Date.now()
      for key of changes when key isnt 'id'
        timestamps[key] = now

    @time.set classname, id, timestamps

    # Update list
    if classname is TASK and changes.list?
      oldTask = @user.findModel classname, id
      if oldTask.list isnt changes.list
        @taskMove id, oldTask.list, changes.list

    # Save to server
    model = @user.updateModel classname, id, changes
    log "Updated #{ classname }: #{ model.name }"

    return model



  ########################################
  #    __   ___  __  ___  __   __        #
  #   |  \ |__  /__`  |  |__) /  \ \ /   #
  #   |__/ |___ .__/  |  |  \ \__/  |    #
  #                                      #
  ########################################

  # Delete existing model
  destroy: (classname, id, timestamp) =>
    model = @user.findModel classname, id

    # Check that the model hasn't been updated after this event
    timestamp ?= Date.now()
    return unless @time.check classname, id, timestamp

    # Destroy all tasks within that list
    if classname is LIST
      for taskId in model.tasks
        log "Destroying Task #{ taskId }"
        @destroy [TASK, taskId]

    # Remove from list
    else if classname is TASK
      @taskRemove id, model.list

    # Replace task with deleted template
    @user.setModel classname, id,
      id: id
      deleted: yes

    # Set timestamp
    @time.set classname, id, 'deleted', timestamp
    log "Destroyed #{ classname } #{ id }"



  #############################################################
  #    __   ___  ___              ___     __            __    #
  #   /  \ |__  |__  |    | |\ | |__     /__` \ / |\ | /  `   #
  #   \__/ |    |    |___ | | \| |___    .__/  |  | \| \__,   #
  #                                                           #
  #############################################################

  # Merge a queue of actions
  sync: (queue) =>

    CREATE = 0
    UPDATE = 1
    DESTROY = 2

    ###
      Queue Format

      <classname>:{
        <id>: [
          <event>
          <model>
          <time>
        ]
      }

      Legend

      classname: 'task', 'list', or 'pref'
      id: 'c10', 's10'
      event: 0, 1, 2
      model: model or id
      time: object[int] or int

    ###

    # Map client IDs to server IDs -- for lists only
    lists = {}

    # LISTS

    if queue.list
      for id, items of queue.list
        for [event, model, time] in items
          switch event

            when CREATE
              model.id = id
              lists[id] = @create 'list', model, time

            when UPDATE
              @update 'list', model, time

            when DESTROY
              @destroy 'list', model, time

    # TASKS

    if queue.task
      for id, items of queue.task
        for [event, model, time] in items
          switch event

            when CREATE
              if lists[model.list]
                model.list = lists[model.list]
              @create 'task', model, time

            when UPDATE
              if model.list and lists[model.list]
                model.list = lists[model.list]
                @update 'task', model, time

            when DESTROY
              @destroy 'task', model, time
    
    # PREFS
    
    if queue.pref
      for id, items of queue.task
        for [event, model, time] in items
          switch event

            when UPDATE
              @update 'pref', model, time


    return [@user.exportModel(TASK), @user.exportModel(LIST)]


  # ----------
  # Task Order
  # ----------

  # Add a task to a list
  taskAdd: (taskId, listId) ->
    tasks = @user.findModel(LIST, listId).tasks
    return false unless tasks
    if tasks.indexOf(taskId) < 0
      tasks.push taskId
      @user.updateModel LIST, listId, tasks:tasks

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

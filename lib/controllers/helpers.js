const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')
const ArchivedTask = require('../models/archivedtask')

const listAttributes = [
  'id',
  'name',
  'notes',
  'updatedAt',
  'createdAt',
  'order'
]
const userAttributes = ['id', 'friendlyName', 'email']
const fullTaskAttributes = [
  'id',
  'name',
  'type',
  'notes',
  'completed',
  'date',
  'deadline',
  'updatedAt',
  'createdAt'
]

const tasksDetails = function(fullDetails = false, reqQuery, userId, listId) {
  return new Promise((resolve, reject) => {
    const taskModel = {
      model: Task,
      attributes: ['id', 'updatedAt', 'createdAt']
    }
    // if we mutate fullDetails, bad things seem to happen :|
    if (fullDetails || ('tasks' in reqQuery && reqQuery.tasks.length > 0)) {
      taskModel.attributes = fullTaskAttributes

      if ('tasks' in reqQuery) {
        const options = reqQuery.tasks.split(',')
        taskModel.where = { id: options }
      }
    }
    const query = {
      attributes: listAttributes,
      include: [
        {
          model: User,
          attributes: userAttributes,
          where: {
            id: userId
          }
        },
        taskModel
      ]
    }
    List.findById(listId, query)
      .then(function(list) {
        if (list) {
          resolve(list)
        } else {
          reject({ code: 404, message: 'List could not be found.' })
        }
      })
      .catch(function(err) {
        reject({ code: 400, message: 'Invalid input syntax.' })
      })
  })
}

const archiveTasks = function(tasks, userId, listId) {
  return new Promise((resolve, reject) => {
    let taskList = null
    if ('tasks' in tasks) {
      taskList = tasks.tasks.split(',')
    }
    tasksDetails(true, {}, userId, listId)
      .then(list => {
        // For each of these tasks, add to archive list for both users
        const promises = []
        const toRemove = []
        const tasksObject = {}
        list.toJSON().tasks.forEach(item => {
          tasksObject[item.id] = item
        })
        list.users.forEach(user => {
          // this should traverse in order
          let currentHeader = null
          const adding = list
            .toJSON()
            .order.map(function(itemOrdered) {
              const item = tasksObject[itemOrdered]
              if (item.type === 'header' || item.type === 'header-collapsed') {
                currentHeader = item.name
              }
              item.header = currentHeader
              item.list = list.name
              return {
                ogId: item.id,
                data: JSON.stringify(item),
                userId: user.id
              }
            })
            .filter(item => {
              if (taskList === null || taskList.indexOf(item.ogId) > -1) {
                toRemove.push(item.ogId)
                return true
              }
              return false
            })
          promises.push(
            ArchivedTask.bulkCreate(adding, {
              validate: true
            })
          )
        })
        Promise.all(promises).then(() => {
          // remove item if it's found
          const newOrder = JSON.parse(JSON.stringify(list.order)).filter(
            function(item) {
              return toRemove.indexOf(item) === -1
            }
          )
          list
            .update({
              order: newOrder
            })
            .then(function() {
              Task.destroy({
                where: {
                  id: toRemove
                }
              }).then(function() {
                resolve(toRemove)
              })
            })
        })
      })
      .catch(reject)
  })
}

module.exports = {
  tasksDetails: tasksDetails,
  archiveTasks: archiveTasks,
  fullTaskAttributes: fullTaskAttributes
}

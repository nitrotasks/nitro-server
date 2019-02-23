const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')
const ArchivedTask = require('../models/archivedtask')
const Meta = require('../models/meta')

const listOrderKey = 'list-order'

const listAttributes = [
  'id',
  'name',
  'notes',
  'sort',
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
  'priority',
  'updatedAt',
  'createdAt'
]
const filterByUser = userId => {
  return {
    model: User,
    attributes: [],
    where: {
      id: userId
    }
  }
}

const tasksDetails = function(fullDetails = false, reqQuery, userId, listId) {
  return new Promise((resolve, reject) => {
    const taskModel = {
      model: Task,
      attributes: ['id', 'updatedAt', 'createdAt']
    }
    // if we mutate fullDetails, bad things seem to happen :|
    const showAllDetails =
      fullDetails || ('tasks' in reqQuery && reqQuery.tasks.length > 0)
    if (showAllDetails) {
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
          if (showAllDetails) {
            list.tasks = list.tasks.map(t => {
              t.priority = t.priority === null ? 0 : t.priority
              return t
            })
          }
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

const getListOrder = async userId => {
  const currentListOrder = await Meta.findOne({
    where: { key: listOrderKey },
    include: filterByUser(userId)
  })
  let parsedCorrectly = false
  try {
    currentListOrder.value.slice()
    parsedCorrectly = true
  } catch (err) {
    // do nothing
  }
  if (currentListOrder === null || parsedCorrectly === false) {
    // needs to create data for the first time
    const lists = await List.findAll({
      attributes: ['id', 'createdAt'],
      include: filterByUser(userId),
      order: [['createdAt', 'DESC']]
    })
    const newOrder = lists.map(i => i.id)
    await Meta.create({
      key: listOrderKey,
      value: newOrder,
      userId: userId
    })
    // should take the second execution path the next time
    return await getListOrder(userId)
  }
  return currentListOrder
}

const appendToListOrder = async (userId, listId) => {
  const currentListOrder = await getListOrder(userId)
  let newOrder = currentListOrder.value.slice()
  let index = newOrder.indexOf(listId)

  // checks to make sure that item is not already in list
  if (index === -1) {
    newOrder.push(listId)

    await currentListOrder.update({
      value: newOrder
    })
  }
}

const removeFromListOrder = async (userId, listId) => {
  const currentListOrder = await getListOrder(userId)
  let newOrder = currentListOrder.value.slice()
  let index = newOrder.indexOf(listId)

  // checks to make sure that item is already in list
  if (index > -1) {
    newOrder.splice(index, 1)

    await currentListOrder.update({
      value: newOrder
    })
  }
}

module.exports = {
  tasksDetails: tasksDetails,
  archiveTasks: archiveTasks,
  fullTaskAttributes: fullTaskAttributes,
  getListOrder: getListOrder,
  appendToListOrder: appendToListOrder,
  removeFromListOrder: removeFromListOrder,
  filterByUser: filterByUser
}

const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')

const fullTaskAttributes = ['id', 'name', 'type', 'notes', 'completed', 'date', 'deadline', 'updatedAt', 'createdAt']

const tasksDetails = function(fullDetails = false, reqQuery, userId, listId) {
  return new Promise((resolve, reject) => {
    let listAttributes = ['id', 'name', 'notes', 'updatedAt', 'createdAt', 'order']
    let userAttributes = ['id', 'friendlyName', 'email']
    let taskModel = {
      model: Task,
      attributes: ['id', 'updatedAt', 'createdAt']
    }
    // if we mutate fullDetails, bad things seem to happen :|
    if (fullDetails || ('tasks' in reqQuery && reqQuery.tasks.length > 0))  {
      taskModel.attributes = fullTaskAttributes

      if ('tasks' in reqQuery) {
        const options = reqQuery.tasks.split(',')
        taskModel.where = {
          id: options
        }
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
    List.findById(listId, query).then(function(list) {
      if (list) {
        resolve(list)
      } else {
        reject({code: 404, message: 'List could not be found.'})
      }
    }).catch(function(err) {
      console.log(err)
      reject({code: 400, message: 'Invalid input syntax.'})
    })
  })
}

module.exports = {
  tasksDetails: tasksDetails,
  fullTaskAttributes: fullTaskAttributes
}
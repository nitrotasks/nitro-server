const stats = require('express').Router()
const passport = require('passport')
const sequelize = require('sequelize')

const User = require('../models/user')
const List = require('../models/list')
const Task = require('../models/task')
const ArchivedTask = require('../models/archivedtask')
const Meta = require('../models/meta')
const auth = passport.authenticate('bearer', { session: false })

// TODO: need to lock this down to admin users only - verify scopes
stats.get('/', auth, async (req, res) => {
  const userStats = User.findAll({
    attributes: [
      [sequelize.fn('COUNT', sequelize.col('username')), 'user_count']
    ]
  })
  const listStats = List.findAll({
    attributes: [[sequelize.fn('COUNT', sequelize.col('id')), 'list_count']]
  })
  const taskStats = Task.findAll({
    attributes: [[sequelize.fn('COUNT', sequelize.col('id')), 'task_count']]
  })
  const archivedTaskStats = ArchivedTask.findAll({
    attributes: [
      [sequelize.fn('COUNT', sequelize.col('id')), 'archivedtask_count']
    ]
  })
  const metaStats = Meta.findAll({
    attributes: [[sequelize.fn('COUNT', sequelize.col('id')), 'meta_count']]
  })

  const data = await Promise.all([
    userStats,
    listStats,
    taskStats,
    archivedTaskStats,
    metaStats
  ])

  res.send({
    counts: {
      users: parseInt(data[0][0].dataValues.user_count),
      lists: parseInt(data[1][0].dataValues.list_count),
      tasks: parseInt(data[2][0].dataValues.task_count),
      archivedtasks: parseInt(data[3][0].dataValues.archivedtask_count),
      meta: parseInt(data[4][0].dataValues.meta_count)
    }
  })
})

module.exports = stats

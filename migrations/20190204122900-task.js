module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.addColumn(
      'tasks',
      'priority',
      Sequelize.INTEGER
    )
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.removeColumn('tasks', 'priority')
  }
}

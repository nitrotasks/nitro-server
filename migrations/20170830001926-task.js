module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.addColumn(
      'tasks',
      'completed',
      Sequelize.DATE
    )
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.removeColumn('tasks', 'completed')
  }
}

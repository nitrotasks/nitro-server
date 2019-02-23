module.exports = {
  up: function(queryInterface, Sequelize) {
    return queryInterface.addColumn('lists', 'sort', Sequelize.STRING)
  },

  down: function(queryInterface, Sequelize) {
    return queryInterface.removeColumn('lists', 'sort')
  }
}

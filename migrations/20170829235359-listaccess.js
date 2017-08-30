module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.createTable('listaccess', {
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE,
      listId: {
        type: Sequelize.UUID,
        references: {
          model: 'lists',
          key: 'id'
        }
      },
      userId: {
        type: Sequelize.UUID,
        references: {
          model: 'users',
          key: 'id'
        }
      },
    })
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.dropTable('listaccess')
  }
}

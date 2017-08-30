module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.createTable('tasks', { 
      id: {
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
      },
      name: Sequelize.STRING,
      type: Sequelize.STRING,
      notes: Sequelize.TEXT,
      date: Sequelize.DATE,
      deadline: Sequelize.DATE,
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE,
      listId: {
        type: Sequelize.UUID,
        references: {
          model: 'lists',
          key: 'id'
        }
      },
    })
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.dropTable('tasks')
  }
}

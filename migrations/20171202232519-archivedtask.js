module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.createTable('archivedtasks', { 
      id: {
        primaryKey: true,
        type: Sequelize.INTEGER,
        autoIncrement: true
      },
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE,
      date: { 
        type: Sequelize.DATE, 
        defaultValue: Sequelize.NOW
      },
      data: Sequelize.TEXT,
      userId: {
        type: Sequelize.UUID,
        references: {
          model: 'users',
          key: 'id'
        }
      }
    })
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.dropTable('archivedtasks')
  }
}

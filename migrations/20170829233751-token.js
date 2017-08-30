module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.createTable('tokens', {
      id: {
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
      },
      expires: Sequelize.DATE,
      userAgent: Sequelize.STRING,
      userId: {
        type: Sequelize.UUID,
        references: {
          model: 'users',
          key: 'id'
        }
      },
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE,
    })
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.dropTable('tokens')
  }
}

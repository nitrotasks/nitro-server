module.exports = {
  up: function(queryInterface, Sequelize) {
    return queryInterface.createTable('metas', {
      id: {
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4
      },
      key: Sequelize.STRING,
      value: Sequelize.JSONB,
      userId: {
        type: Sequelize.UUID,
        references: {
          model: 'users',
          key: 'id'
        }
      },
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE
    })
  },

  down: function(queryInterface, Sequelize) {
    return queryInterface.dropTable('metas')
  }
}

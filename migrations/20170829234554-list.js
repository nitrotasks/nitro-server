module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.createTable('lists', { 
      id: {
        primaryKey: true,
        type: Sequelize.UUID,
        defaultValue: Sequelize.UUIDV4,
      },
      name: Sequelize.STRING,
      // unlimited. Might have to truncate in the controller.
      notes: Sequelize.TEXT,

      // only works in postgres? do we want to support other databases?
      order: {
        type: Sequelize.ARRAY(Sequelize.UUID),
        defaultValue: []
      },
      createdAt: Sequelize.DATE,
      updatedAt: Sequelize.DATE,
    })
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.dropTable('lists')
  }
}
module.exports = {
  up: function (queryInterface, Sequelize) {
    return queryInterface.sequelize.query('CREATE EXTENSION IF NOT EXISTS "uuid-ossp";').then(function() {
      return queryInterface.addColumn(
        'listaccess',
        'id',
        {
          primaryKey: true,
          allowNull: false,
          type: Sequelize.UUID,
          defaultValue: Sequelize.literal('uuid_generate_v4()'),
        }
      )
    })
  },

  down: function (queryInterface, Sequelize) {
    return queryInterface.removeColumn('listaccess', 'id')
  }
}
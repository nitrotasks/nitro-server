const users = require('express').Router()
const passport = require('passport')
const bcrypt = require('bcrypt')
const User = require('../models/user')
const Token = require('../models/token')

users.post('/create', function(req, res) {
  // TODO: actual validation for username and password
  if (req.body
    && 'username' in req.body
    && 'password' in req.body
    && req.body.username !== '' 
    && req.body.password !== '') {
    User.create({
      username: req.body.username,
      email: req.body.username,
      loginType: 'email',
      password: bcrypt.hashSync(req.body.password, 10),
    }).then(function(user) {
      // duplicate from authentication, maybe link into same function
      Token.create({
        expires: new Date(),
        userId: user.get('id'),
        userAgent: req.headers['user-agent'],
      }).then(function(token) {
        res.send({
          refresh_token: token.id,
          expires: token.expires,
        })
      })
    }).catch(function(err) {
      res.status(400).send({message: 'Username is already taken.'})
    })
  } else {
    res.status(400).send({message: 'Username or Password was not supplied.'})
  }
})
users.delete('/', passport.authenticate('bearer', { session: false }), function(req, res) {
  User.destroy({
    where: {
      id: req.user
    }
  }).then(function(user) {
    if (user) {
      res.send({message: 'User Deleted.'})
    } else {
      res.status(404).send({message: 'User not found.'})
    }
  })
})

module.exports = users
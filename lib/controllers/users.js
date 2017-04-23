const users = require('express').Router()
const passport = require('passport')
const bcrypt = require('bcrypt')
const User = require('../models/user')

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
    }).then(function(data) {
      res.send({message: 'User Created.'})
    }).catch(function(err) {
      res.status(400).send({message: 'Username is already taken.'})
    })
  } else {
    res.status(400).send({message: 'Username or Password was not supplied.'})
  }
})

users.get('/meta', passport.authenticate('bearer', { session: false }), function(req, res) {
  res.send(req.user)
})

module.exports = users
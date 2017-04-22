const authentication = require('express').Router()
const bcrypt = require('bcrypt')
const uuid = require('uuid/v1')
const User = require('../models/user')
const Token = require('../models/token')

authentication.post('/authorize', function(req, res) {
  if (req.body.username !== '' 
    && req.body.password !== '') {
    User.findOne({
      where: {
        username: req.body.username
      },
      attributes: ['id', 'password']
    }).then(function(user) {
      if (bcrypt.compareSync(req.body.password, user.password)) {
        Token.create({
          token: uuid(),
          expires: new Date(),
          userId: user.get('id'),
          userAgent: req.headers['user-agent'],
        }).then(function(token) {
          res.send({
            token: token.token,
            expires: token.expires,
          })
        }).catch(function(err) {
          res.send()
        })
      } else {
        console.log('sending here...')
        res.status(401).send({message: 'Username or Password does not match.'})
      }
    }).catch(function(err) {
      // username not found
      res.status(401).send({message: 'Username or Password does not match.'})
    })
  } else {
    res.status(400).send({message: 'Username or Password was not supplied.'})
  }
})

module.exports = authentication
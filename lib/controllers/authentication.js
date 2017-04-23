const authentication = require('express').Router()
const bcrypt = require('bcrypt')
const jwt = require('jsonwebtoken')
const config = require('../../config')
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
          expires: new Date(),
          userId: user.get('id'),
          userAgent: req.headers['user-agent'],
        }).then(function(token) {
          res.send({
            refresh_token: token.id,
            expires: token.expires,
          })
        }).catch(function(err) {
          res.status(500).send({message: 'could not create token.'})
        })
      } else {
        res.status(401).send({message: 'username or password does not match.'})
      }
    }).catch(function(err) {
      // username not found
      res.status(401).send({message: 'username or password does not match.'})
    })
  } else {
    res.status(400).send({message: 'username or password was not supplied.'})
  }
})

authentication.post('/token', function(req, res) {
  if (req.body.refresh_token !== '') {
    // the idea is that we can use JWT to give out stateless access tokens that expire automatically within a day
    Token.find({
      token: req.body.refresh_token
    }).then(function(data) {
      // TODO: Check if Expired

      // 12hr expiry
      const expires = 60*60*12
      const token = jwt.sign({
        user: data.userId
      }, config.jwtsecret, {
        expiresIn: expires
      })

      res.send({
        access_token: token,
        expiresIn: expires
      })
    }).catch(function(err) {
      // token not found
      res.status(401).send({message: 'refresh_token was incorrect.'})
    })
  } else {
    res.status(400).send({message: 'refresh_token was not supplied.'})
  }
})

module.exports = authentication
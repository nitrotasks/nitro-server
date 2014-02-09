Promise    = require 'bluebird'
path       = require 'path'
nodemailer = require 'nodemailer'
keychain   = require '../utils/keychain'
Log        = require '../utils/log'

# create reusable transport method (opens pool of SMTP connections)
smtpTransport = nodemailer.createTransport 'SMTP',
  host: 'mail.nitrotasks.com'
  secureConnection: yes
  port: 465
  auth:
    user: process.env.EMAIL_USER || keychain 'email_user'
    pass: process.env.EMAIL_PASS || keychain 'email_pass'

###
mailOptions =
  from: 'NitroTasks' # sender address
  to: ''             # list of receivers
  subject: ''        # Subject line
  text: ''           # plaintext body
  html: ''           # html body
###

sendMail = Promise.promisify(smtpTransport.sendMail, smtpTransport)

Mail =

  send: (options) ->
    console.log "Sending mail to #{ options.to }"
    options.from ?= 'Nitro Tasks <hello@nitrotasks.com>'
    sendMail options

  verify: (context) ->
    Mail.send
      to: context.email
      subject: context.subject
      text: context.text


# if you don't want to use this transport object anymore, uncomment following line
# smtpTransport.close(); // shut down the connection pool, no more messages

module.exports = Mail

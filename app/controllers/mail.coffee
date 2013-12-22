nodemailer = require 'nodemailer'
Q          = require 'kew'
KeyChain   = require '../utils/keychain'
Log        = require '../utils/log'

# create reusable transport method (opens pool of SMTP connections)
smtpTransport = nodemailer.createTransport 'SMTP',
  host: 'mail.nitrotasks.com'
  secureConnection: yes
  port: 465
  auth:
    user: 'hello@nitrotasks.com'
    pass: KeyChain('hello@nitrotasks.com')

###
mailOptions =
  from: 'NitroTasks' # sender address
  to: ''             # list of receivers
  subject: ''        # Subject line
  text: ''           # plaintext body
  html: ''           # html body
###

sendMail = (options) ->
  deferred = Q.defer()
  # send mail with defined transport object
  smtpTransport.sendMail options, (error, response) ->
    if error
      Log error
    else
      Log 'Message sent: ' + response.message
  deferred.promise

Mail =
  send: (options) ->
    Log "Sending mail to #{ options.to }"
    options.from ?= 'Nitro Tasks <hello@nitrotasks.com>'
    sendMail options

# if you don't want to use this transport object anymore, uncomment following line
# smtpTransport.close(); // shut down the connection pool, no more messages

module.exports = Mail

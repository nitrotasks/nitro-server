nodemailer = require "nodemailer"
Q          = require "q"
KeyChain   = require "./keychain"

# create reusable transport method (opens pool of SMTP connections)
smtpTransport = nodemailer.createTransport "SMTP",
  host: "mail.nitrotasks.com"
  secureConnection: yes
  port: 465
  auth:
    user: "hello@nitrotasks.com"
    pass: KeyChain("hello@nitrotasks.com")

###
mailOptions =
  from: "NitroTasks" # sender address
  to: ""             # list of receivers
  subject: ""        # Subject line
  text: ""           # plaintext body
  html: ""           # html body
###

sendMail = (options) ->
  deferred = Q.defer()
  # send mail with defined transport object
  smtpTransport.sendMail options, (error, response) ->
    if error
      console.log error
    else
      console.log "Message sent: " + response.message
  deferred.promise

Mail =
  send: (options) ->
    options.from ?= "NitroTasks"
    sendMail options

# if you don't want to use this transport object anymore, uncomment following line
# smtpTransport.close(); // shut down the connection pool, no more messages

module.exports = Mail

Mail.send
  to: "dev@stayradiated.com"
  subject: "Hi Stayrad"
  text: "What are you doing today?"

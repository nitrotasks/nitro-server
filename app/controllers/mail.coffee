Q          = require 'kew'
path       = require 'path'
nodemailer = require 'nodemailer'
emTemplate = require 'swig-email-templates'
keychain   = require '../utils/keychain'
Log        = require '../utils/log'

# Setup templates

template = Q.bindPromise emTemplate, undefined,
  root: path.join __dirname, '../../template/email/'

render = (filename, context) ->
  template().then (rnd) ->
    console.log 'got render function'
    console.log 'calling render for', filename, context
    Q.nfcall rnd, filename, context


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
    console.log "Sending mail to #{ options.to }"
    options.from ?= 'Nitro Tasks <hello@nitrotasks.com>'
    sendMail options

  verify: (context) ->
    render('base.html', context).then (result) ->
      console.log 'got result', result
      Mail.send
        to: context.user.email
        subject: context.subject
        html: result


# if you don't want to use this transport object anymore, uncomment following line
# smtpTransport.close(); // shut down the connection pool, no more messages

module.exports = Mail

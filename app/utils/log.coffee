
colors =
  'reset':      '\u001b[0m'
  'bold':       '\u001b[1m'
  'italic':     '\u001b[3m'
  'underline':  '\u001b[4m'
  'blink':      '\u001b[5m'
  'black':      '\u001b[30m'
  'red':        '\u001b[31m'
  'green':      '\u001b[32m'
  'yellow':     '\u001b[33m'
  'blue':       '\u001b[34m'
  'magenta':    '\u001b[35m'
  'cyan':       '\u001b[36m'
  'white':      '\u001b[37m'

# Easy way to disable logging if needed
module.exports = (name, color='reset') ->
  prefix = "#{colors[color]}[#{name}]#{colors.reset}"
  return (args...) =>
    args.unshift(prefix)
    console.log(args...)

# Easy way to disable logging if needed
Log = (args...) =>
  # return unless process.env.NODE_ENV is "development"
  args.unshift('(Sync)')
  console.log(args...)
module.exports = Log

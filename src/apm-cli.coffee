_ = require 'underscore-plus'
colors = require 'colors'
optimist = require 'optimist'
wordwrap = require 'wordwrap'

commandClasses = [
  require './clean'
  require './dedupe'
  require './develop'
  require './featured'
  require './init'
  require './install'
  require './links'
  require './link'
  require './list'
  require './login'
  require './publish'
  require './rebuild'
  require './search'
  require './test'
  require './uninstall'
  require './unlink'
  require './unpublish'
  require './update'
  require './view'
]

commands = {}
for commandClass in commandClasses
  for name in commandClass.commandNames ? []
    commands[name] = commandClass

parseOptions = (args=[]) ->
  options = optimist(args)
  options.usage """

    apm - Atom Package Manager powered by https://atom.io

    Usage: apm <command>

    where <command> is one of:
    #{wordwrap(4, 80)(Object.keys(commands).sort().join(', '))}.

    Run `apm help <command>` to see the more details about a specific command.
  """
  options.alias('v', 'version').describe('version', 'Print the apm version')
  options.alias('h', 'help').describe('help', 'Print this usage message')
  options.boolean('color').default('color', true).describe('color', 'Enable colored output')
  options.command = options.argv._[0]
  for arg, index in args when arg is options.command
    options.commandArgs = args[index+1..]
    break
  options

module.exports =
  run: (args, callback) ->
    options = parseOptions(args)

    unless options.argv.color
      colors.setTheme
        cyan: 'stripColors'
        green: 'stripColors'
        red: 'stripColors'
        yellow: 'stripColors'

    callbackCalled = false
    options.callback = (error) ->
      return if callbackCalled
      callbackCalled = true
      if error?
        callback?(error)
        if _.isString(error)
          message = error
        else
          message = error.message ? error

        if message is 'canceled'
          # A prompt was canceled so just log an empty line
          console.log()
        else if message
          console.error(message.red)

        process.exit(1)
      else
        callback?()

    args = options.argv
    command = options.command
    if args.version
      apmVersion =  require('../package.json').version
      npmVersion = require('../node_modules/npm/package.json').version
      nodeVersion = process.versions.node
      console.log """
        apm  #{apmVersion}
        npm  #{npmVersion}
        node #{nodeVersion}
      """
    else if args.help
      if Command = commands[options.command]
        new Command().showHelp(options.command)
      else
        options.showHelp()
    else if command
      if command is 'help'
        if Command = commands[options.commandArgs]
          new Command().showHelp(options.commandArgs)
        else
          options.showHelp()
      else if Command = commands[command]
        new Command().run(options)
      else
        options.callback("Unrecognized command: #{command}")
    else
      options.showHelp()

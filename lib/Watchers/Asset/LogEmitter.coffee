EventEmitter = require('events').EventEmitter

class LogEmitter extends EventEmitter
    constructor: ->
        super()

    # Reconfigure the logger to use hapi's events
    useHapi: (plugin = @plugin)->
        hapiLog = (tags, data)->
            plugin.log tags, data
        @outLog = ->
        @outErr = ->
        @on 'err', (_)=>
            hapiLog ['error', 'stassets', _.name], "#{_.name}: #{_.message}"
        @on 'log', (_)=>
            hapiLog ['stassets', _.name], "#{_.name}: #{_.message}"

    # Log output methods
    outLog: (_)->
        console.log _
    outErr: (_)->
        console.error _

    # Object formatters
    logString: (_)->
        timestamp = (new Date()).toISOString()
        caller = @constructor.name
        value = JSON.stringify _
        "#{timestamp} #{caller} :: #{value}"
    logObject: (_)->
        timestamp = new Date().toISOString()
        name = @constructor.name
        message = _
        {timestamp, name, message}

    # Default log methods
    log: (_)->
        @emit 'log', @logObject _
        return unless @config.verbose
        @outLog @logString _
    err: (_)->
        @emit 'err', @logObject _
        return unless @config.verbose
        @outErr @logString _

    # Builder specific log helpers
    printStart: (loader)->
        @log "Rendering: #{loader.path}"
    printError: (where, message)->
        @err "Could not #{where}: #{message}"
    printSuccess: ->
        @log "Finished building asset"

module.exports = LogEmitter

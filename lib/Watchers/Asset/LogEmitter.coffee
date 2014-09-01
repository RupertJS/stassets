EventEmitter = require('events').EventEmitter

class LogEmitter extends EventEmitter
    constructor: ->
        super()
    logString: (_)->
        timestamp = (new Date()).toISOString()
        caller = @constructor.name
        value = JSON.stringify _
        "#{timestamp} #{caller}:: #{value}"
    logObject: (_)->
        timestamp = new Date().toISOString()
        name = @constructor.name
        message = _
        {timestamp, name, message}
    log: (_)->
        @emit 'log', @logObject _
        return unless @config.verbose
        console.log @logString _
    err: (_)->
        @emit 'err', @logObject _
        return unless @config.verbose
        console.error @logString _
    printStart: (loader)->
        @log "Rendering: #{loader.path}"
    printError: (where, message)->
        @err "Could not #{where}: #{message}"
    printSuccess: ->
        @log "Finished building asset"

module.exports = LogEmitter

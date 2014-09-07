EventEmitter = require('events').EventEmitter
debug = require('debug')

class LogEmitter extends EventEmitter
    constructor: ->
        super()
        @debug = debug("stassets:#{@constructor.name}")
        @error = debug("stassets:ERROR:#{@constructor.name}")
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
        @debug _
    err: (_)->
        @emit 'err', @logObject _
        @error
    printStart: (loader)->
        @log "Rendering: #{loader.path}"
    printError: (where, message)->
        @err "Could not #{where}: #{message}"
    printSuccess: ->
        @log "Finished building asset"

module.exports = LogEmitter

tinylr = require('tiny-lr')

class LiveReload
    constructor: (@options = {})->
        @options.port ?= 35729

        @server = tinylr @options
        @server.server.removeAllListeners 'error'
        @server.server.on 'error', (err)=>
            if err.code is 'EADDRINUSE'
                console.error 'Port ' + @options.port +
                    ' is already in use by another process.'
            else
                console.err err
            process.exit 1 if @options.failHard
        @server.listen @options.port, (err)=>
            # return grunt.fatal(err) if err
            console.log "Live reload server starting on port #{@options.port}."

    watch: (watcher)->
        watcher.on 'Compiled', (ev)=>
            @server.changed({body: {files: ev.files}})

module.exports = LiveReload

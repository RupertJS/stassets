Path = require 'path'
fs = require 'graceful-fs'
Q = require 'q'

readFile = Q.denodeify fs.readFile
Mirror = require '../mirror'
sha1 = require 'sha1'

EventEmitter = require('events').EventEmitter

class Loader
    constructor: (@path, watcher)->
        defer = Q.defer()
        @promise = defer.promise
        encoding = watcher.encoding()
        readFile(@path, {encoding}).then(
            ((@code)=> defer.resolve([@code, @])),
            ((@err)=> defer.reject([@err, @]))
        )

class Logger extends EventEmitter
    logString: (_)->
        "#{(new Date()).toISOString()} #{@constructor.name}:: #{_}"
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

class AssetWatcher extends Logger
    constructor: ->
        @_defer = Q.defer()
        @promise = @_defer.promise
        @content = ""
        @filelist = {}
        @config = @config or {verbose: no}
        @config.root = (@config.root or ['./']).map Path.normalize

        @watch new Mirror(
            @pattern()
            @config.howMany
        )

    pattern: (patterns)->
        rootPatterns = (pattern)=>
            if pattern.indexOf('!') is 0
                [pattern]
            else
                @config.root.map (root)->
                    "#{root}/#{pattern}"
        flatten = (a, v)->a.concat(v)
        fullList = patterns.map(rootPatterns).reduce(flatten, [])
        fullList

    watch: (@gaze)->
        @printedEMFILE = @printedEMFILE or no
        @gaze.on 'error', (_)=>
            switch _.code
                when 'EMFILE'
                    unless @printedEMFILE
                        file = _.message.match(/"([^"]+)"/)?[1] or 'ERR_FILE'
                        console.log 'EMFILE', file
                        console.log 'This is likely due to a large watch list.'
                        console.log 'It will still work, but be slow (polling).'
                        console.log 'Consider using `ulimit -n` to raise limit.'
                        console.log ''
                        @printedEMFILE = yes
                else
                    console.log _.code

        @gaze.on 'ready', =>
            @gaze.watched (err, filelist = {})=>
                return console.log err if err
                Object.keys(filelist).forEach (file)=>
                    @add file
                @compile()

        @gaze.on 'added', (_)=> @add _ ; @compile()
        @gaze.on 'deleted', (_) => @remove _ ; @compile()
        @gaze.on 'changed', (_)=> @compile()
        @gaze.on 'renamed', (n, o)=> @remove o ; @add n ; @compile()

    add: (filepath)->
        if fs.statSync(filepath).isFile()
            @filelist[filepath] = yes

    remove: (filepath)->
        @filelist[filepath] = no
        delete @filelist[filepath]

    pathpart: (path)->
        for root in @config.root
            path = path.replace(root, '')
        path

    ###
    This should return an array of files in the correct insert order.
    ###
    getFilenames: ->
        list = Object.keys(@filelist)
        hset = {}
        list.forEach (path)=>
            hset[@pathpart(path)] = path
        hlist = (v for k, v of hset)
        hlist

    getPaths: -> []
    matches: (path)-> path in @getPaths()
    type: -> "application/javascript"

    handle: (req, res, next)->
        res.status(200).set('Content-Type', @type()).send(@content)

    hash: ->
        sha1 @content

    encoding: -> 'utf-8'

    ###
    The compile function orchestrates the load / render / concat loop.
    Unsurprisingly, there are three links in the promise chain. The first builds
    an array of `Loader`s, one for each file to load. The `Loader` does the fs
    to the source file, and resolves with that code and a reference to itself
    (for metadata). The second passes each `Loader`'s source to a subclass'
    `render` function, which can return either the rendered file, or a promise
    for the render. Finally, the list of render promises are joined and passed
    to the concatenator. The result of that step is the value assigned to
    `this.content`.
    ###
    compile: ->
        filenames = @getFilenames()

        console.log @logString "Compiling #{filenames}..."

        readMap = filenames.map (_)=> (new Loader(_, @)).promise

        renderMap = readMap.map (_)=>
            d = Q.defer()
            _.then ([__, loader])=>
                @printStart loader
                try
                    d.resolve @render __, loader.path
                catch err
                    d.reject err
            _.catch ([__, loader])=>
                @printError "read `#{loader.path}`", @formatReadError __
                Q ''
            d.promise
        Q.all(renderMap)
        .catch (__)=>
            @printError 'render', @formatRenderError __
            Q ''
        .then((_)=> Q @concat _)
        .catch (__)=>
            @printError 'concat', @formatConcatError __
        .then((_)=> @finish(_))
        .done()

        @

    render: (_, path)-> _
    concat: (_)-> _.join('\n')
    finish: (_)->
        @printSuccess()
        @content = _
        @emit 'Compiled', {name: @constructor.name, files: @getPaths()}
        @_defer.resolve()

    formatReadError: (error, loader)-> error
    formatRenderError: (error, loader)-> error
    formatConcatError: (error)-> error

module.exports = AssetWatcher

Path = require 'path'
fs = require 'fs'
Q = require 'q'

readFile = Q.denodeify fs.readFile
# stat = Q.denodeify fs.stat

sha1 = require 'sha1'

Gaze = require('gaze').Gaze
minimatch = require 'minimatch' # TODO Remove after
                                # https://github.com/shama/gaze/issues/104
                                # gets resolved

class Loader
    constructor: (@path, watcher)->
        defer = Q.defer()
        @promise = defer.promise
        encoding = watcher.encoding()
        readFile(@path, {encoding}).then(
            ((@code)=> defer.resolve([@code, @])),
            ((@err)=> defer.reject([@err, @]))
        )

class Logger
    logString: (_)->
        "#{(new Date()).toISOString()} #{@constructor.name}:: #{_}"
    log: (_)-> console.log @logString _
    err: (_)-> console.error @logString _
    printStart: (loader)->
        return unless @config.verbose
        @log "Rendering: #{loader.path}"
    printError: (where, message)->
        return unless @config.verbose
        @err "Could not #{where}: #{message}"
    printSuccess: ->
        return unless @config.verbose
        @log "Finished building asset"

class AssetWatcher extends Logger
    constructor: ->
        @content = ""
        @filelist = {}

        unless @pattern? and @pattern instanceof Array
            throw new Error "No sane pattern, have #{@pattern}"

        watch = (filepath)=> # TODO Remove [shama/gaze/issues/104]
            for pattern in @pattern
                if minimatch filepath, pattern
                    return true
            false

        @gaze = new Gaze @pattern

        @gaze.on 'error', (_)=> console.log _

        @gaze.on 'ready', =>
            @gaze.watched (err, matched = {})=>
                return console.log err if err
                for _, files of matched
                    files
                    .filter watch
                    .forEach (filepath)=>
                        if fs.statSync(filepath).isFile()
                            @filelist[filepath] = yes
                @compile()
        @gaze.on 'added', (_)=> @add _ if watch _
        @gaze.on 'deleted', (_) => @remove _ if watch _
        @gaze.on 'changed', (_)=> @compile() if watch _

    add: (filepath)->
        if fs.statSync(filepath).isFile()
            @filelist[filepath] = yes
            @compile()

    remove: (filepath)->
        if fs.statSync(filepath).isFile()
            @filelist[filepath] = no
            delete @filelist[filepath]
            @compile()

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
        filenames = Object.keys(@filelist)

        # console.log "Compiling #{filenames}..."

        readMap = filenames.map (_)=> (new Loader(_, @)).promise

        renderMap = readMap.map (_)=>
            d = Q.defer()
            _.then ([__, loader])=>
                try
                    @printStart loader
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
        .then (_)=> Q @concat _
        .done ((_)=> @printSuccess() ; @content = _), (__)=>
            @printError 'concat', @formatConcatError __

    render: (_, path)-> _
    concat: (_)-> _.join('\n')

    formatReadError: (error, loader)-> error
    formatRenderError: (error, loader)-> error
    formatConcatError: (error)-> error

module.exports = AssetWatcher

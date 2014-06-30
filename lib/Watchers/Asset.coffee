Path = require 'path'
fs = require 'graceful-fs'
Q = require 'q'

readFile = Q.denodeify fs.readFile
Mirror = require '../mirror'
sha1 = require 'sha1'

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
    log: (_)->
        return unless @config.verbose
        console.log @logString _
    err: (_)->
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

        @watch new Mirror(
            @config.root
            @extensions()
            @pattern()
            @config.noAdd or no
        )

    extensions: ->
        @pattern().map (pat)->
            pat.match(/\.([a-z]+)$/)[1]

    watch: (@gaze)->
        @gaze.on 'error', (_)=>
            debugger
            switch _.code
                when 'EMFILE'
                    file = _.message.match(/"([^"]+)"/)[1]
                    console.log "EMFILE", file
                else
                    console.log _.code

        @gaze.on 'ready', =>
            @gaze.watched (err, @filelist = {})=>
                return console.log err if err
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

    ###
    This should return an array of files in the correct insert order.
    ###
    getFilenames: ->
        Object.keys(@filelist)

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

        # console.log "Compiling #{filenames}..."

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
        @_defer.resolve()

    formatReadError: (error, loader)-> error
    formatRenderError: (error, loader)-> error
    formatConcatError: (error)-> error

module.exports = AssetWatcher

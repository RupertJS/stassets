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

class AssetWatcher
    constructor: ->
        @content = ""
        @filelist = {}

        unless @pattern? and @pattern instanceof Array
            throw new Error "No sane pattern, have #{@pattern}"

        @gaze = new Gaze @pattern

        @gaze.on 'error', (_)=> console.log _

        @gaze.on 'ready', =>
            @gaze.watched (err, matched = {})=>
                return console.log err if err
                for _, files of matched
                    files
                    .filter (filepath)=> # TODO Remove [shama/gaze/issues/104]
                        for pattern in @pattern
                            if minimatch filepath, pattern
                                return true
                        false
                    .forEach (filepath)=>
                        if fs.statSync(filepath).isFile()
                            @filelist[filepath] = yes
                @compile()
        @gaze.on 'added', (_)=> @add _
        @gaze.on 'deleted', (_) => @remove _
        @gaze.on 'changed', (_)=> @compile()

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
                    d.resolve @render __, loader.path
                catch err
                    d.reject err
            _.catch ([__, loader])=>
                console.error "Could not read #{loader.path}; error was", __
                d.reject __
            d.promise

        Q.all(renderMap)
        .catch (__)=>
            console.error "Could not render #{@constructor.name}; error was", __
            Q.reject __
        .then (_)=> Q @concat _
        .done (_)=> @content = _

    render: (_, path)-> _
    concat: (_)-> _.join('\n')

module.exports = AssetWatcher

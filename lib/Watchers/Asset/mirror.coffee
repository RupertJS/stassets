fs = require 'graceful-fs'
Path = require 'path'
EventEmitter = require('./LogEmitter')
Q = require 'q'
nb = require 'nextback'
# Gaze = require('gaze').Gaze
# Watch = require('gaze').Gaze
Watch = require('sane')
minimatch = require 'minimatch'

eventMap =
    add: 'added'
    added: 'added'
    delete: 'deleted'
    deleted: 'deleted'
    change: 'changed'
    changed: 'changed'

Pool = {}
GetPool = (root)->
    root = Path.resolve process.cwd(), root
    root = './' if root is '' # Prevent enumerating fs root when run in cwd.
    try
        Pool[root] or= new Watch root
    catch err
        err.root = root
        throw err

class Mirror extends EventEmitter
    constructor: (@root, @pattern, @config = {verbose: no, howMany: 'some'})->
        super()
        unless @root? and @root instanceof Array or @config.noRoot is true
            throw new Error "No sane roots; have #{@root}, need Array"
        unless @pattern? and @pattern instanceof Array
            throw new Error "No sane pattern; have #{@pattern}, need Array."

        @warnings = {}

        @pool = []
        if @config.noRoot
            # Need to load one and only one
            for file in @pattern
                do =>
                    for dir in root
                        try
                            path = Path.normalize "#{dir}/#{file}"
                            @pool.push GetPool path
                            @log "Found #{path}"
                            return
                        catch e
                            # Nothing
                    throw new Error "Could not find file #{file}"
        else
            # Try to load them all
            for file in @root
                try
                    @pool.push GetPool file
                catch e
                    @handleError e
        @gazeAt @pool

    gazeAt: (pool)->
        Q.all pool.map (pond)=>
            d = Q.defer()
            if @config.noRoot
                # Ready immediately
                d.resolve()
            else
                pond.on 'ready', -> d.resolve()
            d.promise
        .then =>
            @emit 'ready'
        pool.forEach (pond)=>
            pond.on 'error', (err)=> @emit 'error', err
            pond.on 'all', (eventName, path)=>
                if @toWatch path
                    @emit 'all', eventMap[eventName], path
                    # @emit eventMap[eventName], path
                    # TODO wait on amasad/sane#21
            for k, v of eventMap
                do (k, v)=>
                    pond.on k, (path)=>
                        if @toWatch pond.root + '/' + path
                            @emit v, pond.root + '/' + path
            return
        @

    handleError: (err)->
        @err err
        if err.code is 'EMFILE'
            unless @warnings.EMFILE
                @log
                    code: EMFILE
                    message: """
                    The operating system does not have enough file handles to
                    enumerate all files. On linux or OSX, try doubling the
                    available file handles with
                    `ulimit -n $(( $(ulimit -n ) * 2))`
                    """
                    root: err.root
            @warnings.EMFILE = yes
        if err.code is 'ENOENT'
            unless @warnings.ENOENT
                @log
                    err: err
                    message: """
                    A watch directory didn't exist.
                    """
                    root: err.root
            @warnings.ENOENT = yes

    toWatch: (filepath)=>
        return true if @config.noRoot # Already found it
        @pattern.some (pattern)->
            if pattern instanceof RegExp
                if pattern.test filepath
                    return true
            if typeof pattern is 'string'
                try
                    if minimatch(filepath, pattern)
                        return true
                    else
                        if filepath.indexOf(pattern) > -1
                            return true
                catch e
                    return false
            return false

    watched: (cb)->
        cb = nb cb
        filelist = {}
        @pool.forEach (pond)=>
            Object.keys(pond.dirRegistery).forEach (dirname)=>
                dir = pond.dirRegistery[dirname]
                Object.keys(dir).forEach (file)=>
                    path = Path.join dirname, file
                    if @toWatch path
                        filelist[path] = true
            Object.keys(pond.watched).forEach (path)=>
                if @toWatch path
                    filelist[path] = true
        cb null, filelist

module.exports = Mirror

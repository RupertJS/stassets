fs = require 'graceful-fs'
Path = require 'path'
EventEmitter = require('events').EventEmitter
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
GetPool = (root, extensions, noGlob)->
    root = Path.resolve process.cwd(), root
    root = './' if root is '' # Prevent enumerating fs root when run in cwd.
    Pool[root] or= new Watch root

class Mirror extends EventEmitter
    constructor: (@root, @pattern, @howMany = 'some')->
        unless @root? and @root instanceof Array
            throw new Error "No sane roots; have #{@root}, need Array"
        unless @pattern? and @pattern instanceof Array
            throw new Error "No sane pattern; have #{@pattern}, need Array."

        # if noGlob then extensions = @pattern

        # @pond = GetPool root, extensions, noGlob
        # @gazeAt gaze for gaze in @pond
        # @gazeAt @gaze = new Gaze @pattern
        @gazeAt @pool = (GetPool(root) for root in @root)

    gazeAt: (pool)->
        minmatch = (path)-> (pattern)-> minimatch path, pattern
        pool.forEach (pond)=>
            pond.on 'error', (err)=> @emit 'error', err
            pond.on 'ready', => @emit 'ready'
            pond.on 'all', (eventName, path)=>
                @pattern
                .filter(minmatch(path))
                .forEach (pattern)=>
                    @emit 'all', eventMap[eventName], path
                    @emit eventMap[eventName], path
            for k, v of eventMap
                pond.on k, (path)=> @emit v, path

    toWatch: -> (filepath)=>
        # console.log "Checking #{filepath} against #{@pattern}"
        # @pattern[@howMany] (pattern)->
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
        # @gaze.watched (err, matched = {})=>
        #     return cb err if err
        #     filelist = {}
        #     for _, files of matched
        #         files
        #         .filter(@toWatch())
        #         .forEach (filepath)=>
        #             filelist[filepath] = yes
        #     cb null, filelist

        filelist = {}
        @pool.forEach (pond)=>
            files = Object.keys(pond.dirRegistery).forEach (dirname)=>
                dir = pond.dirRegistery[dirname]
                Object.keys(dir).forEach (file)=>
                    path = "#{dirname}/#{file}"
                    if @toWatch() path
                        filelist[path] = true

        cb null, filelist

module.exports = Mirror

fs = require 'fs'
Path = require 'path'
EventEmitter = require('events').EventEmitter
Gaze = require('gaze').Gaze
minimatch = require 'minimatch' # TODO Remove after
                                # https://github.com/shama/gaze/issues/104
                                # gets resolved

Pool = {}

GetPool = (root)->
    root = Path.relative process.cwd(), root
    root = './' if root is '' # Prevent enumerating fs root when run in cwd.
    Pool[root] = Pool[root] or new Gaze "#{root}/**/*"

class Mirror extends EventEmitter
    constructor: (root, @pattern)->
        unless @pattern? and @pattern instanceof Array
            throw new Error "No sane pattern; have #{@pattern}, need Array."

        @gaze = GetPool root
        @gaze.setMaxListeners 0 # Unlimited; TODO Consider rearchitecting.

        minmatch = (path)-> (pattern)-> minimatch path, pattern

        @gaze.on 'error', (err)=> @emit 'error', err
        @gaze.on 'ready', => @emit 'ready'
        @gaze.on 'all', (eventName, path)=>
            @pattern
            .filter(minmatch(path))
            .forEach (pattern)=>
                @emit 'all', eventName, path
                @emit eventName, path

    toWatch: -> (filepath)=> # TODO Remove [shama/gaze/issues/104]
        for pattern in @pattern
            if minimatch filepath, pattern
                return true
        false

    watched: (cb)->
        @gaze.watched (err, matched = {})=>
            return cb err if err
            filelist = {}
            for _, files of matched
                files
                .filter(@toWatch())
                .forEach (filepath)=>
                    filelist[filepath] = yes
            cb null, filelist

module.exports = Mirror

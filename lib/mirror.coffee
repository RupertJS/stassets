fs = require 'graceful-fs'
Path = require 'path'
EventEmitter = require('events').EventEmitter
Gaze = require('gaze').Gaze
minimatch = require 'minimatch' # TODO Remove after
                                # https://github.com/shama/gaze/issues/104
                                # gets resolved
Q = require 'q'
Pool = {}

GetPool = (root, extensions, noGlob)->
    root = Path.relative process.cwd(), root
    root = './' if root is '' # Prevent enumerating fs root when run in cwd.
    extensions.map (ext)->
        watch = if noGlob
                "#{root}/#{ext}"
            else
                "#{root}/**/*.#{ext}"
        Pool[watch] = Pool[watch] or new Gaze watch

class Mirror extends EventEmitter
    constructor: (root, extensions, @pattern, noGlob)->
        unless @pattern? and @pattern instanceof Array
            throw new Error "No sane pattern; have #{@pattern}, need Array."

        if noGlob then extensions = @pattern

        @pond = GetPool root, extensions, noGlob
        @gazeAt gaze for gaze in @pond

    gazeAt: (gaze)->
        minmatch = (path)-> (pattern)-> minimatch path, pattern
        gaze.on 'error', (err)=> @emit 'error', err
        gaze.on 'ready', => @emit 'ready'
        gaze.on 'all', (eventName, path)=>
            @pattern
            .filter(minmatch(path))
            .forEach (pattern)=>
                @emit 'all', eventName, path
                @emit eventName, path


    toWatch: -> (filepath)=> # TODO Remove [shama/gaze/issues/104]
        for pattern in @pattern
            if minimatch(filepath, pattern) or filepath.indexOf(pattern) > -1
                return true
        false

    watched: (cb)->
        filelist = {}

        Q.all @pond.map (gaze)=>
            d = Q.defer()
            debugger
            gaze.watched (err, matched = {})=>
                return d.reject err if err
                for _, files of matched
                    files
                    .filter(@toWatch())
                    .forEach (filepath)=>
                        filelist[filepath] = yes
                d.resolve()
            d.promise
        .catch(cb)
        .done -> cb null, filelist

module.exports = Mirror

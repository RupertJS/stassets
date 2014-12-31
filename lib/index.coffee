fs = require 'graceful-fs'
Path = require 'path'
Q = require 'q'
LR = require './livereload'

class Stassets
    constructor: (@config)->
        for prop, val of Stassets.DEFAULTS
            @config[prop] or= val

        @config.root = [@config.root] unless @config.root instanceof Array

        @watchers = [
            "Vendor/Script"
            "Vendor/Style"
            "Template"
            "Script"
            "Style/All"
            "Style/Print"
            "Style/Screen"
            "Index"
        ].map (watcher)=>
            Ctor = require("./Watchers/#{watcher}")
            new Ctor @config

        @promise = Q.all(@watchers.map (_)->_.promise)

        unless @config.livereload is no
            @livereload = new LR @config.livereload
            @watchers.forEach (watcher)=>
                @livereload.watch watcher

    handle: (req, res, next)->
        for watcher in @watchers
            if watcher.matches req.path
                return watcher.handle(req, res, next)
        next()

Stassets.DEFAULTS =
    verbose: no
    root: ['.']
    vendors:
        prefix: "./"
        js: [ '' ]
        css: [ '' ]
    livereload:
        port: 35729

middleware = (config)->
    stassets = new Stassets(config)
    fn = (req, res, next)->
        stassets.handle(req, res, next)
    fn.watchers = stassets.watchers
    fn.promise = stassets.promise
    fn

middleware.Stassets = Stassets
middleware.Constructors = require('./constructors')

module.exports = middleware

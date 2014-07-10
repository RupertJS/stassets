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
        prefix: "../bower_components"
        js: [ 'angular/angular.js' ]
        css: [ 'bootstrap/dist/css/*.css' ]
    livereload:
        port: 35729

middleware = (config)->
    stassets = new Stassets(config)
    middleware.watchers = stassets.watchers
    (req, res, next)->
        stassets.handle(req, res, next)

middleware.Stassets = Stassets

module.exports = middleware

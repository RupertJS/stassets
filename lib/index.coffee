fs = require 'fs'
Path = require 'path'
sha1 = require 'sha1'
Q = require 'q'

glob = require 'glob'

class Stassets
    constructor: (@config)->
        for prop, val of Stassets.DEFAULTS
            @config[prop] or= val

        @config.root = Path.normalize @config.root

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

    handle: (req, res, next)->
        for watcher in @watchers
            if watcher.matches req.path
                return watcher.handle(req, res, next)
        next()

Stassets.DEFAULTS =
    verbose: no
    root: '.'
    vendors:
        prefix: "#{__dirname}/../bower_components"
        js: [ 'angular/angular.js' ]
        css: [ 'bootstrap/dist/css/*' ]

middleware = (config)->
    stassets = new Stassets(config)
    middleware.watchers = stassets.watchers
    (req, res, next)->
        stassets.handle(req, res, next)

middleware.Stassets = Stassets

module.exports = middleware

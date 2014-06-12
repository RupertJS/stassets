debounce = require 'debounce'
fs = require 'fs'
Path = require 'path'
sha1 = require 'sha1'
q = require 'q'

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

    handle: (req, res, next)->
        for watcher in @watchers
            if watcher.matches req.path
                return watcher.handle(req, res, next)
        next()

Stassets.DEFAULTS =
    root: '.'
    vendors:
        prefix: "#{__dirname}/../bower_components"
        js: [ 'angular/angular.js' ]
        css: [ 'bootstrap/dist/css/*' ]

module.exports = (config)->
    stassets = new Stassets(config)
    (req, res, next)->
        stassets.handle(req, res, next)

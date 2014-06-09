debounce = require 'debounce'
fs = require 'fs'
Path = require 'path'
sha1 = require 'sha1'
q = require 'q'
Gaze = require('gaze').Gaze
minimatch = require 'minimatch' # TODO Remove after
                                # https://github.com/shama/gaze/issues/104
                                # gets resolved
jade = require 'jade'
glob = require 'glob'

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
        @filelist[filepath] = yes
        @compile()

    remove: (filepath)->
        @filelist[filepath] = yes
        delete @filelist[filepath]
        @compile()

    type: -> "application/javascript; charset=utf-8"

    handle: (req, res, next)->
        res.status(200).set('Content-Type', @type()).send(@content)

    hash: ->
        sha1 @content

class IndexWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = [ "#{@config.root}/index.jade" ]
        super()

    matches: (path)-> path in ['/', '/index.html']
    type: -> "text/html; charset=utf-8"

    compile: ->
        return @content = '' if Object.keys(@filelist).length  < 1
        fs.readFile Object.keys(@filelist)[0], (err, content)=>
            return if err
            @content = jade.render content,
                filename: "#{@config.root}/index.jade"

class TemplateWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = ["#{@config.root}/**/template.jade"]
        super()

    matches: (path)-> path in ['/templates.js', "/templates-#{@hash()}.js"]

    compile: ->
        render = (path)=>
            shortPath = path
                .replace(@config.root + '/', '')
                .replace('.jade', '')
            module = shortPath.replace /\//g, '.'
            templatePath = shortPath.replace('/template', '')
            options =
                filename: path
            code = fs.readFileSync(path).toString('utf-8')
            content = require('jade').render(code, options)
            """
            angular.module('#{module}', [])
            .run(function($templateCache){
                $templateCache.put('#{shortPath}', '#{escapeContent(content)}');
            });
            """
        @content = Object.keys(@filelist).map(render).join('\n')

class ScriptWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = [
            'main'
            'directive'
            'service'
            'controller'
            'filter'
            'provider'
        ].map (_)=> "#{@config.root}/**/#{_}.coffee"
        super()

    matches: (path)=> path is '/application.js'

    compile: ->
        render = (path)=>
            options =
                filename: path
                literate: no
            code = fs.readFileSync(path).toString('utf-8')
            require('coffee-script').compile(code, options)
        console.log "Compiling #{Object.keys(@filelist)}"
        @content = Object.keys(@filelist).map(render).join('\n')

# Normalize backslashes and strip newlines.
escapeContent = (content)->
    content
    .replace(/\\/g, '\\\\').replace(/'/g, '\\\'')
    .replace(/\r?\n/g, '\\n\' +\n    \'')

class Stassets
    constructor: (@config)->
        for prop, val of Stassets.DEFAULTS
            @config[prop] or= val

        @config.root = Path.normalize @config.root

        @watchers = [
            IndexWatcher
            TemplateWatcher
            ScriptWatcher
        ].map (Ctor)=>
            new Ctor @config

    handle: (req, res, next)->
        for watcher in @watchers
            if watcher.matches req.path
                return watcher.handle(req, res, next)
        next()

Stassets.DEFAULTS =
    root: '.'

module.exports = (config)->
    stassets = new Stassets(config)
    (req, res, next)->
        stassets.handle(req, res, next)

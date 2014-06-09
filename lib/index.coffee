debounce = require 'debounce'
fs = require 'fs'
Path = require 'path'
sha1 = require 'sha1'

jade = require 'jade'
glob = require 'glob'

class AssetWatcher
    constructor: ->
        @filelist = {}
        @gaze = new Gaze @pattern
        @gaze.on 'all', (_)=> @add _

    add: (filepath)->
        @filelist[filepath] = yes

    compile: ->


    hash: ->
        sha1 @contents

class

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

        @partials =
            index: fs.readFileSync "#{@config.root}/index.jade"
            templates: glob.sync "#{@config.root}/**/template.jade"

    index: (req, res, next)->
        res.status(200)
            .set('Content-Type', 'text/html')
            .send jade.render @partials.index,
                filename: "#{@config.root}/index.jade"

    templates: (req, res, next)->
        render = (path)=>
            shortPath = path
                .replace(@config.root + '/', '')
                .replace('.jade', '')
            module = shortPath.replace /\//g, '.'
            templatePath = shortPath.replace('/template', '')
            content = jade.render(fs.readFileSync(path), {filename: path})
            """
            angular.module('#{module}', [])
            .run(function($templateCache){
                $templateCache.put('#{shortPath}', '#{escapeContent(content)}');
            });
            """
        res.status(200).send @partials.templates.map(render).join('\n')

    handle: (req, res, next)->
        switch req.path
            when '/index.html' then @index(req, res, next)
            when '/templates.js' then @templates(req, res, next)
            else next()

Stassets.DEFAULTS =
    root: '.'

module.exports = (config)->
    stassets = new Stassets(config)
    (req, res, next)->
        stassets.handle(req, res, next)

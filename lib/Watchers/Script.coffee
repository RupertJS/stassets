fs = require 'fs'
SourcemapWatcher = require './Sourcemap'
Generator = require('source-map').SourceMapGenerator
SourceNode = require('source-map').SourceNode

class ScriptWatcher extends SourcemapWatcher
    constructor: (@config)->
        types = @config.types || [
            'main'
            'directive'
            'service'
            'controller'
            'filter'
            'provider'
        ].concat @config.additionalTypes

        prefix = (ext)=> (_)=> "#{@config.root}/**/#{_}.#{ext}"
        @pattern = types.map(prefix('js')).concat(types.map(prefix('coffee')))
        @files = ['/app.js', '/application.js']
        super()

    render: (code, path)->
        extension = path.substr(path.lastIndexOf('.') + 1)
        ScriptWatcher.renderers[extension].call(this, code, path)

ScriptWatcher.renderers =
    js: (content, path)->
        sourceNode = new SourceNode 1, 0, path.replace "#{@config.root}/", ''
        sourceNode.add content.split '\n'
        sourceMap = sourceNode.toStringWithSourceMap().map.toJSON()
        sourceMap.sourcesContent = [content]
        {content, sourceMap}

    coffee: (code, path)->
        options =
            filename: path
            literate: no
            sourceMap: yes
            sourceRoot: ''
            sourceFiles: [path.replace "#{@config.root}/", '']

        build = require('coffee-script').compile(code, options)
        content = build.js#.replace(/\n/gm, '')
        sourceMap = JSON.parse build.v3SourceMap
        sourceMap.sourcesContent = [code]
        {content, sourceMap}

module.exports = ScriptWatcher

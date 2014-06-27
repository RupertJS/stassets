fs = require 'fs'
SourcemapWatcher = require './Sourcemap'
Generator = require('source-map').SourceMapGenerator
SourceNode = require('source-map').SourceNode

esprima = require 'esprima'

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

        prefix = (ext)=> (_)=> "**/#{_}.#{ext}"
        @pattern = []
            .concat(types.map(prefix('js')))
            .concat(types.map(prefix('coffee')))
        @files = ['/app.js', '/application.js']
        super()

    render: (code, path)->
        extension = path.substr(path.lastIndexOf('.') + 1)
        ScriptWatcher.renderers[extension].call(this, code, path)

ScriptWatcher.renderers =
    js: (content, path)->
        source = file = path.replace "#{@config.root}/", ''

        generator = new Generator({file})
        esprima.tokenize(content, {loc: yes}).forEach (token)->
            loc = token.loc.start
            original = {line: loc.line, column: loc.column}
            generated = {line: loc.line + 1, column: loc.column}
            mapping = {generated, original, source}
            if token.type is 'Identifier'
                mapping.name = token.value
            generator.addMapping mapping

        sourceMap = generator.toJSON()
        sourceMap.sourcesContent = [content]

        content = "(function(){\n#{content}\n}).call(this);\n"
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

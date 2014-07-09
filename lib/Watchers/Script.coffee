Q = require 'q'
fs = require 'graceful-fs'
SourcemapWatcher = require './Sourcemap'
Generator = require('source-map').SourceMapGenerator
SourceNode = require('source-map').SourceNode
minimatch = require 'minimatch'

esprima = require 'esprima'
UglifyJS = require 'uglify-js'
ngmin = require 'ngmin'

class ScriptWatcher extends SourcemapWatcher
    constructor: (@config)->
        @files = ['/app.js', '/application.js']
        @config.types = @config.types || [
            'main'
            'provider'
            'filter'
            'service'
            'controller'
            'directive'
        ].concat(@config.additionalTypes or [])
        @config.typeList = @config.typeList or [
            'js'
            'coffee'
        ].concat(@config.additionalTypeList or [])
        super()

    pattern: ->
        prefix = (_)=> "**/#{_}.{#{@config.typeList.join(',')}}"
        super @config.types.map(prefix)

    patternOrder: (path)->
        p = @config.types
        i = 0
        while i < p.length
            if path.indexOf("#{p[i]}.") > -1
                break
            i++
        i

    getFilenames: ->
        Object
            .keys(@filelist)
            .filter((filename)-> filename.indexOf('test.') is -1)
            .sort (a, b)=>
                order = @patternOrder(a) - @patternOrder(b)
                if order is 0
                    if a > b
                        1
                    else if a < b
                        -1
                    else
                        0
                else
                    order

    render: (code, path)->
        extension = path.substr(path.lastIndexOf('.') + 1)
        ScriptWatcher.renderers[extension].call(this, code, path)

    concat: (_)->
        {content, sourceMap} = super _
        return Q {content, sourceMap} unless @config.compressJS

        content = ngmin.annotate content
        result = UglifyJS.minify content,
            fromString: true
            inSourceMap: sourceMap
            outSourceMap: "app.js.map"

        Q {content: result.code, sourceMap: result.map}

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

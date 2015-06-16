Q = require 'q'
fs = require 'graceful-fs'
SourcemapWatcher = require './Sourcemap'
Generator = require('source-map').SourceMapGenerator
SourceNode = require('source-map').SourceNode
minimatch = require 'minimatch'

esprima = require 'esprima'
UglifyJS = require 'uglify-js'
flatten = require 'flatten-source-map'

class ScriptWatcher extends SourcemapWatcher
    constructor: (@config)->
        @files = ['/app.js', '/application.js']
        @config.scripts or= {}
        @config.scripts.types = @config.scripts.types || [ 'main' ]
        super()

    pattern: ->
        types = Object.keys(ScriptWatcher.renderers)
        @log types
        prefix = (_)-> "**/*#{_}.{#{types.join(',')}}"
        typeList = @config.scripts.types.map(prefix)
        super typeList

    patternOrder: (path)->
        p = @config.scripts.types
        i = 0
        while i < p.length
            if path.indexOf("#{p[i]}.") > -1
                break
            i++
        i

    getFilenames: ->
        super()
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

    minify: ({content, sourceMap})->
        if typeof sourceMap isnt "undefined"
            generatedMap = flatten(sourceMap)

            result = UglifyJS.minify content,
                fromString: true
                inSourceMap: generatedMap
                outSourceMap: "app.js.map"
        else
            result = UglifyJS.minify content,
                fromString: true

        {content: result.code, sourceMap: generatedMap || ""}

    concat: (_)->
        res = super _ # {content, sourceMap}
        res = @minify res if @config.scripts.compress
        Q res

ScriptWatcher.renderers =
    js: (content, path)->
        source = file = @pathpart path

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
        {content, sourceMap, path}

    coffee: (code, path)->
        options =
            filename: path
            literate: no
            sourceMap: yes
            sourceRoot: ''
            sourceFiles: [@pathpart path]

        build = require('coffee-script').compile(code, options)
        content = build.js#.replace(/\n/gm, '')
        sourceMap = JSON.parse build.v3SourceMap
        sourceMap.sourcesContent = [code]
        {content, sourceMap, path}

module.exports = ScriptWatcher

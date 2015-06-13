SourcemapWatcher = require './Sourcemap'
SourceMapGenerator = require('source-map').SourceMapGenerator
htmlMinifier = require('html-minifier')

class TemplateWatcher extends SourcemapWatcher
    constructor: (@config)->
        @config.templates or= {}
        @config.templateGlobal or= "Templates"
        @files = ['/templates.js']
        super()

    pattern: ->
        types = Object.keys(TemplateWatcher.renderers)
        super ["**/*template.{#{types.join(',')}}"]

    getPaths: -> @files

    getShortPath: (path)->
        types = Object.keys(TemplateWatcher.renderers)
        short = @pathpart(path)
        .replace(/^\//, '')
        .replace(///\.(?:#{types.join('|')})$///, '')
        .replace(/[\-\/]template$/, '')
        pc = short.split('/')
        if pc[pc.length - 1] is pc[pc.length - 2] then pc.pop()
        pc.join('/')

    render: (code, path)->
        extension = path.substr(path.lastIndexOf('.') + 1)
        content = TemplateWatcher.renderers[extension].call(this, code, path)
        @wrap(path, content, code)

    cache: (path)->
        shortPath = @getShortPath path

        pre = [
            "Templates", "[", "'", shortPath, "'", "]", " ", "=", " ", "'"
        ]
        post = [
            "'", ";"
        ]

        {pre, post}

    wrap: (path, rendered, code)->
        {pre, post} = @cache(path)

        source = file = @pathpart path

        generator = new SourceMapGenerator({file})
        original = { line: 1, column: 0 }
        generated = { line: 1, column: 0 }

        content = ''
        addMap = (arr, isSource = no)->
            for part in arr
                content += part
                generator.addMapping { source, generated, original }
                generated.column += part.length
                if isSource
                    original.column += part.length

        addMap(pre)
        addMap([rendered], yes)
        addMap(post)

        sourceMap = generator.toJSON()
        sourceMap.sourcesContent = [code]

        {content, sourceMap, path}

    formatRenderError: (error)->
        error.toLocaleString()

    concat: (_)->
        prefix = "window.#{@config.templateGlobal} = {};";
        _.unshift {content: prefix, sourceMap: null}
        super(_)

TemplateWatcher.renderers =
    html: (code, path)->
        content = htmlMinifier.minify(code, {
          removeComments: true
          collapseWhitespace: true
        })
        .replace(/\\/g, '\\\\')
        .replace(/'/g, '\\\'')
    jade: (code, path)->
        # Normalize backslashes and strip newlines.a
        escapeContent = (content)->
            min = content
            .replace(/\\/g, '\\\\')
            .replace(/'/g, '\\\'')
            .replace(/\r?\n/g, '\\n')
            min

        options = filename: path
        content = require('jade').render(code, options)
        escapeContent(content)

module.exports = TemplateWatcher

fs = require 'graceful-fs'
SourcemapWatcher = require './Sourcemap'
SourceMapGenerator = require('source-map').SourceMapGenerator

class TemplateWatcher extends SourcemapWatcher
    constructor: (@config)->
        @config.templates or= {}
        @files = ['/templates.js']
        super()

    pattern: ->
        types = Object.keys(TemplateWatcher.renderers)
        super ["**/*template.{#{types.join(',')}}"]

    getPaths: -> @files

    getShortPath: (path)->
        @pathpart(path)
        .substr(1)
        .replace('.jade', '')
        .replace(/\\/g, '/') # Normalize pathing.
        .replace('/template', '')

    getModuleName: (shortPath)->
        module = shortPath.replace(/\//g, '.') + '.template'
        if moduleRoot = @config.templates.baseModule
            module = "#{moduleRoot}.#{module}"
        module

    render: (code, path)->
        extension = path.substr(path.lastIndexOf('.') + 1)
        TemplateWatcher.renderers[extension].call(this, code, path)

    wrap: (path, content, code)->
        shortPath = @getShortPath path
        module = @getModuleName shortPath
        source = file = @pathpart path

        content =
            "angular.module('#{module}', [])" +
            ".run(function($templateCache){" +
            "$templateCache.put('#{shortPath}', '#{content}');" +
            "});"

        generator = new SourceMapGenerator({file})

        generated = { line: 3, column: 24 + 4 + shortPath.length }
        original = { line: 1, column: 0 }

        generator.addMapping { source, generated, original }
        sourceMap = generator.toJSON()
        sourceMap.sourcesContent = [code]

        {content, sourceMap, path}

    formatRenderError: (error)->
        error.toLocaleString()

TemplateWatcher.renderers =
    html: (code, path)->
        content = code
            .replace(/^\s+/g, '')
            .replace(/\r?\n\s*/g, '')
            .replace(/\\/g, '\\\\')
            .replace(/'/g, '\\\'')
        @wrap path, content, code
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
        @wrap path, escapeContent(content), code

module.exports = TemplateWatcher

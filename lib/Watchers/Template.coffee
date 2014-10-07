fs = require 'graceful-fs'
SourcemapWatcher = require './Sourcemap'
SourceMapGenerator = require('source-map').SourceMapGenerator

class TemplateWatcher extends SourcemapWatcher
    constructor: (@config)->
        @files = ['/templates.js']
        super()

    pattern: -> super ["**/template.jade"]
    getPaths: -> @files

    getShortPath: (path)->
        @pathpart(path)
        .substr(1)
        .replace('.jade', '')
        .replace(/\\/g, '/') # Normalize pathing.
        .replace('/template', '')

    getModuleName: (shortPath)->
        module = shortPath.replace(/\//g, '.') + '.template'
        if moduleRoot = @getModuleRoot()
            module = "#{moduleRoot}.#{module}"
        module

    getModuleRoot: -> @config.templateModuleRoot

    stripNewlines: (content)->
        content.replace(/\r?\n/g, '\\n\' +\n    \'')

    # Normalize backslashes and strip newlines.
    escapeContent: (content)->
        @stripNewlines(content)
        .replace(/\\/g, '\\\\')
        .replace(/'/g, '\\\'')

    render: (code, path)->
        options = filename: path
        content = require('jade').render(code, options)
        @wrap path, content, code

    wrap: (path, content, code)->
        shortPath = @getShortPath path
        module = @getModuleName shortPath
        source = file = @pathpart path

        content = """
        angular.module('#{module}', [])
        .run(function($templateCache){
            $templateCache.put('#{shortPath}', '#{@escapeContent(content)}');
        });
        """

        generator = new SourceMapGenerator({file})

        generated = { line: 3, column: 24 + 4 + shortPath.length }
        original = { line: 1, column: 0 }

        generator.addMapping { source, generated, original }
        sourceMap = generator.toJSON()
        sourceMap.sourcesContent = [code]

        {content, sourceMap, path}

    formatRenderError: (error)->
        error.toLocaleString()

module.exports = TemplateWatcher

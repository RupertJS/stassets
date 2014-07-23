fs = require 'graceful-fs'
AssetWatcher = require './Asset'

class TemplateWatcher extends AssetWatcher
    constructor: (@config)->
        super()

    pattern: -> super ["**/template.jade"]
    getPaths: -> ['/templates.js', "/templates-#{@hash()}.js"]

    getShortPath: (path)->
        @pathpart(path)
        .substr(1)
        .replace('.jade', '')
        .replace('/template', '')
        .replace('\\', '/') # Fix for windows.

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
        @wrap path, content

    wrap: (path, content)->
        shortPath = @getShortPath path
        module = @getModuleName shortPath

        """
        angular.module('#{module}', [])
        .run(function($templateCache){
            $templateCache.put('#{shortPath}', '#{@escapeContent(content)}');
        });
        """

module.exports = TemplateWatcher

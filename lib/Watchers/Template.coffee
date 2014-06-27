fs = require 'fs'
AssetWatcher = require './Asset'

stripNewlines = (content)->
    content.replace(/\r?\n/g, '\\n\' +\n    \'')

# Normalize backslashes and strip newlines.
escapeContent = (content)->
    stripNewlines(content)
    .replace(/\\/g, '\\\\')
    .replace(/'/g, '\\\'')

class TemplateWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = ["**/template.jade"]
        super()

    matches: (path)-> path in ['/templates.js', "/templates-#{@hash()}.js"]

    render: (code, path)->
        shortPath = path
            .replace(@config.root + '/', '')
            .replace('.jade', '')
        module = shortPath.replace /\//g, '.'
        shortPath = shortPath.replace '/template', ''
        options =
            filename: path
        content = require('jade').render(code, options)
        """
        angular.module('#{module}', [])
        .run(function($templateCache){
            $templateCache.put('#{shortPath}', '#{escapeContent(content)}');
        });
        """

module.exports = TemplateWatcher

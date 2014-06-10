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
        @pattern = ["#{@config.root}/**/template.jade"]
        super()

    matches: (path)-> path in ['/templates.js', "/templates-#{@hash()}.js"]

    compile: ->
        render = (path)=>
            shortPath = path
                .replace(@config.root + '/', '')
                .replace('.jade', '')
            module = shortPath.replace /\//g, '.'
            templatePath = shortPath.replace('/template', '')
            options =
                filename: path
            code = fs.readFileSync(path).toString('utf-8')
            content = require('jade').render(code, options)
            """
            angular.module('#{module}', [])
            .run(function($templateCache){
                $templateCache.put('#{shortPath}', '#{escapeContent(content)}');
            });
            """
        try
            @content = Object.keys(@filelist).map(render).join('\n')
        catch e
            console.log e

module.exports = TemplateWatcher

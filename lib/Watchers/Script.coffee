fs = require 'fs'
SourcemapWatcher = require './Sourcemap'

class ScriptWatcher extends SourcemapWatcher
    constructor: (@config)->
        @pattern = [
            'main'
            'directive'
            'service'
            'controller'
            'filter'
            'provider'
        ].map (_)=> "#{@config.root}/**/#{_}.coffee"
        @files = ['/app.js', '/application.js']
        super()

    render: (code, path)->
        options =
            filename: path
            literate: no
            sourceMap: yes
            sourceRoot: ''
            sourceFiles: [path.replace "#{@config.root}/", '']

        build = require('coffee-script').compile(code, options)
        content = build.js.replace(/\n/gm, '')
        sourceMap = JSON.parse build.v3SourceMap
        sourceMap.sourcesContent = code
        {content, sourceMap}

module.exports = ScriptWatcher

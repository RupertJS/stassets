fs = require 'fs'
AssetWatcher = require './Asset'

class ScriptWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = [
            'main'
            'directive'
            'service'
            'controller'
            'filter'
            'provider'
        ].map (_)=> "#{@config.root}/**/#{_}.coffee"
        super()

    matches: (path)=> path in ['/app.js', '/application.js']

    render: (code, path)->
        options =
            filename: path
            literate: no
        require('coffee-script').compile(code, options).replace(/\n/gm, '')

module.exports = ScriptWatcher

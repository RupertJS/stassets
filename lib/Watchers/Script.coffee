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

    matches: (path)=> path is '/application.js'

    compile: ->
        render = (path)=>
            options =
                filename: path
                literate: no
            code = fs.readFileSync(path).toString('utf-8')
            require('coffee-script').compile(code, options).replace(/\n/gm, '')
        @content = Object.keys(@filelist).map(render).join('\n')

module.exports = ScriptWatcher

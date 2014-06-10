fs = require 'fs'
AssetWatcher = require('./Asset')

class IndexWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = [ "#{@config.root}/index.jade" ]
        super()

    matches: (path)-> path in ['/', '/index.html']
    type: -> "text/html; charset=utf-8"

    compile: ->
        return @content = '' if Object.keys(@filelist).length  < 1
        fs.readFile Object.keys(@filelist)[0], (err, content)=>
            return if err
            @content = require('jade').render content,
                filename: "#{@config.root}/index.jade"

module.exports = IndexWatcher

fs = require 'fs'
AssetWatcher = require('./Asset')

class IndexWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = [ "#{@config.root}/index.jade" ]
        super()

    matches: (path)-> path in ['/', '/index.html']
    type: -> "text/html; charset=utf-8"

    render: (_, filename)->
        require('jade').render _, {filename}

module.exports = IndexWatcher

fs = require 'graceful-fs'
AssetBuilder = require('./Asset')

class IndexWatcher extends AssetBuilder
    constructor: (@config)->
        super()

    pattern: -> super [ "index.jade" ]

    getPaths: -> ['/', '/index.html']
    type: -> "text/html; charset=utf-8"

    render: (_, filename)->
        require('jade').render _, {filename}

module.exports = IndexWatcher

fs = require 'graceful-fs'
AssetBuilder = require('./Asset')

class IndexWatcher extends AssetBuilder
    constructor: (@config)->
        super()

    pattern: -> super [ "index.{html,jade}" ]

    getPaths: -> ['/', '/index.html']
    type: -> "text/html; charset=utf-8"

    render: (_, filename)->
        ext = filename.match(/\.(html|jade)$/)[1]
        if ext is 'jade'
            require('jade').render _, {filename}
        else
            return _

module.exports = IndexWatcher

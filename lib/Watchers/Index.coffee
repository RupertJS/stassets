fs = require 'graceful-fs'
AssetWatcher = require('./Asset')

class IndexWatcher extends AssetWatcher
    constructor: (@config)->
        super()

    pattern: -> [ "**/index.jade" ]

    matches: (path)->
        if @config.deeplink
            # /api is allowed, non deep links are allowed.
            if not path.match /^\/(?:api|[^/]+$)/
                return true
        path in ['/', '/index.html']
    type: -> "text/html; charset=utf-8"

    render: (_, filename)->
        require('jade').render _, {filename}

module.exports = IndexWatcher

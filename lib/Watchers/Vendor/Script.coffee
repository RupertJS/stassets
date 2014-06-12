Path = require 'path'
AssetWatcher = require('../Asset')

class VendorScriptWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = @config.vendors.js.map (_)=>
            Path.normalize "#{@config.vendors.prefix}/#{_}"
        super()

    matches: (path)-> path in ['/vendors.js']
    type: -> "application/javascript"

module.exports = VendorScriptWatcher

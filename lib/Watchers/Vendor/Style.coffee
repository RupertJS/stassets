Path = require 'path'
AssetWatcher = require('../Asset')

class VendorStyleWatcher extends AssetWatcher
    constructor: (@config)->
        @pattern = @config.vendors.css.map (_)=>
            Path.normalize "#{@config.vendors.prefix}/#{_}"
        super(config)

    matches: (path)-> path in ['/vendors.css']
    type: -> "text/css"

module.exports = VendorStyleWatcher

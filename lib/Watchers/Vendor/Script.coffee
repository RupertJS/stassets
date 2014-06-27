Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorScriptWatcher extends VendorWatcher
    constructor: (@config)->
        @pattern = @config.vendors.js
        super()

    matches: (path)-> path in ['/vendors.js']
    type: -> "application/javascript"

module.exports = VendorScriptWatcher

Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorScriptWatcher extends VendorWatcher
    constructor: (@config)->
        super()

    extensions: -> ['js']
    pattern: -> @config.vendors.js
    matches: (path)-> path in ['/vendors.js']
    type: -> "application/javascript"

module.exports = VendorScriptWatcher

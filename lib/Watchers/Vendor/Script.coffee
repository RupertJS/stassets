Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorScriptWatcher extends VendorWatcher
    constructor: (@config)->
        super()

    pattern: -> super @config.vendors.js
    #matches: (path)-> path in ['/vendors.js']
    getPaths: -> ['/vendors.js']
    type: -> "application/javascript"

module.exports = VendorScriptWatcher

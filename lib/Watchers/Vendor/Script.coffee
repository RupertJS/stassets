Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorScriptWatcher extends VendorWatcher
    constructor: (@config)->
        @config.vendors or= {}
        @config.vendors.js or= []
        super()

    pattern: -> super @config.vendors?.js or []
    #matches: (path)-> path in ['/vendors.js']
    getPaths: -> ['/vendors.js']
    type: -> "application/javascript"

module.exports = VendorScriptWatcher

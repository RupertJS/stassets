Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorScriptWatcher extends VendorWatcher
    constructor: (@config)->
        @files = ['/vendors.js']
        @config.vendors or= {}
        @config.vendors.js or= []
        @config.vendors.jsMaps or= []
        super()

    pattern: -> super @config.vendors.js
    getMaps: -> @config.vendors.jsMaps
    type: -> "application/javascript"

module.exports = VendorScriptWatcher

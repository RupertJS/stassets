Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorStyleWatcher extends VendorWatcher
    constructor: (@config)->
        @files = ['/vendors.css']
        @config.vendors or= {}
        @config.vendors.css or= []
        @config.vendors.cssMaps or= []
        super()

    pattern: -> super @config.vendors?.css or []
    getMaps: -> @config.vendors.cssMaps
    type: -> "text/css"

module.exports = VendorStyleWatcher

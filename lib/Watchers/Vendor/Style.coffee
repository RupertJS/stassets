Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorStyleWatcher extends VendorWatcher
    constructor: (@config)->
        @config.vendors or= {}
        @config.vendors.css or= []
        super()

    pattern: -> super @config.vendors?.css or []

    #matches: (path)-> path in ['/vendors.css']
    getPaths: -> ['/vendors.css']

    type: -> "text/css"

module.exports = VendorStyleWatcher

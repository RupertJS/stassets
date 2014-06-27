Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorStyleWatcher extends VendorWatcher
    constructor: (@config)->
        @pattern = @config.vendors.css
        super()

    matches: (path)-> path in ['/vendors.css']
    type: -> "text/css"

module.exports = VendorStyleWatcher

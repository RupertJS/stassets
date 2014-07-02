Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorStyleWatcher extends VendorWatcher
    constructor: (@config)->
        # @config.howMany = 'every'
        super()

    pattern: -> super @config.vendors.css

    matches: (path)-> path in ['/vendors.css']
    type: -> "text/css"

module.exports = VendorStyleWatcher

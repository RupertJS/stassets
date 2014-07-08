Path = require 'path'
VendorWatcher = require('./Vendor')

class VendorStyleWatcher extends VendorWatcher
    constructor: (@config)->
        super()

    pattern: -> super @config.vendors.css

    #matches: (path)-> path in ['/vendors.css']
    getPaths: -> ['/vendors.css']

    type: -> "text/css"

module.exports = VendorStyleWatcher

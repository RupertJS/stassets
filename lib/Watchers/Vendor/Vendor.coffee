Path = require 'path'
AssetWatcher = require '../Asset'
minimatch = require 'minimatch'

class VendorWatcher extends AssetWatcher
    constructor: ->
        @config.vendors or=
            js: []
            css: []
        @config.vendors.prefix or= './'
        @config = JSON.parse JSON.stringify @config # Quick clone hack
        @config.root = [@config.vendors.prefix]

        super()

    vendorOrder: (path)->
        order = Number.MAX_VALUE
        @pattern().forEach (pattern, i)->
            order = i if minimatch path, pattern
        order

    getFilenames: ->
        Object
            .keys(@filelist)
            .sort (a, b)=>
                @vendorOrder(a) - @vendorOrder(b)

module.exports = VendorWatcher

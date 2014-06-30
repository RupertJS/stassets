Path = require 'path'
AssetWatcher = require '../Asset'
minimatch = require 'minimatch'

class VendorWatcher extends AssetWatcher
    constructor: ->
        # Quick clone hack
        @config = JSON.parse JSON.stringify @config
        @config.root = Path.normalize @config.vendors.prefix
        @config.noAdd = yes
        # @pattern = @pattern.map (_)->
        #     if _.indexOf("**/") is 0 then _ else "**/#{_}"
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

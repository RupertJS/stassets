Path = require 'path'
AssetWatcher = require '../Asset'

class VendorWatcher extends AssetWatcher
    constructor: ->
        # Quick clone hack
        @config = JSON.parse JSON.stringify @config
        @config.root = Path.normalize @config.vendors.prefix
        @pattern = @pattern.map (_)->
            if _.indexOf("**/") is 0 then _ else "**/#{_}"
        super()

module.exports = VendorWatcher

StyleWatcher = require './Style'

class AllStyleWatcher extends StyleWatcher
    constructor: (@config)->
        @name = 'all'
        super()

module.exports = AllStyleWatcher

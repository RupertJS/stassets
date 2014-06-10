StyleWatcher = require '../Style'

class ScreenStyleWatcher extends StyleWatcher
    constructor: (@config)->
        @name = 'screen'
        super()

module.exports = ScreenStyleWatcher

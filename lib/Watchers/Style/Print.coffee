StyleWatcher = require './Style'

class PrintStyleWatcher extends StyleWatcher
    constructor: (@config)->
        @name = 'print'
        super()

module.exports = PrintStyleWatcher

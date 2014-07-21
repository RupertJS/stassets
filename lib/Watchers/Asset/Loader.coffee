EventEmitter = require('events').EventEmitter
fs = require 'graceful-fs'
Q = require 'q'
readFile = Q.denodeify fs.readFile

class Loader extends EventEmitter
    constructor: (@path, watcher)->
        super()
        defer = Q.defer()
        @promise = defer.promise
        encoding = watcher.encoding()
        readFile(@path, {encoding}).then(
            ((@code)=> defer.resolve([@code, @])),
            ((@err)=> defer.reject([@err, @]))
        )

module.exports = Loader

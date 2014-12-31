EventEmitter = require('events').EventEmitter
fs = require 'graceful-fs'
Q = require 'q'
readFile = Q.denodeify fs.readFile
statFile = Q.denodeify fs.stat

class Loader extends EventEmitter
    constructor: (@path, watcher, metaOnly = no)->
        super()
        defer = Q.defer()
        @promise = defer.promise
        encoding = watcher.encoding()
        error = ((@err)=> defer.reject([@err, @]))
        unless metaOnly
            readFile(@path, {encoding}).then(
                ((@code)=> defer.resolve([@code, @])),
                error
            )
        else
            statFile(@path).then(
                ((@stat)=> defer.resolve([@stat, @])),
                error
            )

module.exports = Loader

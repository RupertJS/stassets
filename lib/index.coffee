Stassets = require './stassets'

# Express
middleware = (config)->
    stassets = new Stassets(config)
    fn = (req, res, next)->
        stassets.handle(req, res, next)
    fn.watchers = stassets.watchers
    fn.promise = stassets.promise
    fn

middleware.Stassets = Stassets

# Hapi
middleware.register = (plugin, options, next)->
    stassets = new Stassets(options)
    stassets.hapi plugin
    next()

middleware.register.attributes =
    pkg: require('../package.json')

module.exports = middleware

fs = require 'graceful-fs'
AssetWatcher = require './Asset'
q = require 'q'

class StyleWatcher extends AssetWatcher
    constructor: -> super()

    pattern: -> super ["**/#{@name}.styl"]

    type: -> "text/css"
    matches: (path)-> path is "/#{@name}.css"

    render: (code, path)->
        d = q.defer()
        require('stylus')(code)
            .set('filename', path)
            .use(require('nib')()).import('nib')
            .render (err, css)=>
                if err
                    d.reject err
                else
                    d.resolve css
        d.promise

module.exports = StyleWatcher

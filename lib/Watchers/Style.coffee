fs = require 'fs'
AssetWatcher = require './Asset'
q = require 'q'

class StyleWatcher extends AssetWatcher
    constructor: ->
        @pattern = ["#{@config.root}/**/#{@name}.styl"]
        super()

    type: -> "text/css"
    matches: (path)-> path is "/#{@name}.css"

    compile: ->
        render = (path)=>
            d = q.defer()
            require('stylus')(fs.readFileSync(path).toString('utf-8'))
                .set('filename', path)
                .use(require('nib')())
                .import('nib')
                .render (err, css)=>
                    if err
                        d.reject err
                    else
                        d.resolve css
            d.promise
        q.all(Object.keys(@filelist).map(render))
        .then (css...)=>
            @content = css.join '\n'

module.exports = StyleWatcher

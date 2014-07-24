fs = require 'graceful-fs'
AssetWatcher = require '../Asset'
Q = require 'q'
nib = require 'nib'

class StyleWatcher extends AssetWatcher
    constructor: -> super()

    pattern: -> super ["**/#{@name}.styl"]

    type: -> "text/css"
    getPaths: -> ["/#{@name}.css"]

    render: (code, path)->
        d = Q.defer()
        compiler = require('stylus')(code)
            .set('filename', path)
            .use(nib())
            .import('nib')

        @getImports().forEach (_1)-> compiler.include(_1)


        compiler.render (err, css)=>
            if err
                d.reject err
            else
                d.resolve {css, path}

        d.promise

    getVendorImports: ->
        if @config.vendors?.stylus?
            @config.vendors.stylus.map (_1)=>
                @config.vendors.prefix + '/' + _1
        else
            []

    getImports: ->
        imports = @getVendorImports()
        .concat(@config.root.map (_1)-> "#{_1}/stylus/definitions/variables")
        .concat(@config.root.map (_1)-> "#{_1}/stylus/definitions/mixins")

        imports = imports.filter (_1)->
            if _1.indexOf '.css' is -1
                _1 = "#{_1}.styl"
            fs.existsSync _1
        imports

    concat: (styli)->
        Q(styli.map((_)->_.css).join('\n'))

module.exports = StyleWatcher

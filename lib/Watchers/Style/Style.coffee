fs = require 'graceful-fs'
SourcemapWatcher = require '../Sourcemap'
Q = require 'q'
nib = require 'nib'

class StyleWatcher extends SourcemapWatcher
    constructor: ->
        @files = ["/#{@name}.css"]
        super()

    pattern: ->
        types = Object.keys(StyleWatcher.renderers)
        super ["**/#{@name}.{#{types.join(',')}}"]

    type: -> "text/css"

    render: (code, path)->
        extension = path.substr(path.lastIndexOf('.') + 1)
        StyleWatcher.renderers[extension].call(this, code, path)

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

StyleWatcher.renderers =
    styl: (code, path)->
        compiler = require('stylus')(code)
            .set('filename', @pathpart path)
            .use(nib())
            .import('nib')
            .set('sourcemap', { comment: no })

        @getImports().forEach (_1)-> compiler.import(_1)

        try
            content = compiler.render()
            sourceMap = compiler.sourcemap

            sourceMap.sources[0] = @pathpart path
            sourceMap.sourcesContent = sourceMap.sources.map (file, i)->
                if i is 0
                    code
                else
                    fs.readFileSync file, 'utf-8'

            Q {content, sourceMap, path}
        catch err
            Q.reject err
    css: (code, path)-> throw new Error 'Not implemented'

module.exports = StyleWatcher

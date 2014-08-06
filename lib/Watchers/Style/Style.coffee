fs = require 'graceful-fs'
SourcemapWatcher = require '../Sourcemap'
Q = require 'q'
nib = require 'nib'

class StyleWatcher extends SourcemapWatcher
    constructor: ->
        @files = ["/#{@name}.css"]
        super()

    pattern: -> super ["**/#{@name}.styl"]

    type: -> "text/css"

    render: (code, path)->
        compiler = require('stylus')(code)
            .set('filename', path)
            .use(nib())
            .import('nib')
            .set('sourcemap', {rootUrl: @pathpart path})

        @getImports().forEach (_1)-> compiler.import(_1)

        try
            content = compiler.render()
            sourceMap = compiler.sourcemap
            content = content.replace(/^\/\*# sourceMappingURL=.*$/m, '')
            sourceMap.sourcesContent = []
            for file in sourceMap.sources
                if file is path
                    sourceMap.sourcesContent.push code
                else
                    sourceMap.sourcesContent.push fs.readFileSync file, 'utf-8'
            Q {content, sourceMap}
        catch err
            Q.reject err

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

module.exports = StyleWatcher

Q = require 'q'
FS = require 'fs'
Path = require 'path'
AssetWatcher = require '../Sourcemap'
minimatch = require 'minimatch'

R_SOURCE_MAP_COMMENT = ///
(?:/\*|//) # Opening comment
\#\ssourceMappingURL=([^\s]+) # URL
(?:\s+\*/)? # Optional close comment
///

class VendorWatcher extends AssetWatcher
    constructor: ->
        @config.vendors or=
            js: []
            css: []
        @config.vendors.prefix or= './'
        @config = JSON.parse JSON.stringify @config # Quick clone hack
        @config.root = [@config.vendors.prefix]
        @files = @getPaths()

        super()

    findSourceMap: (content, path)->
        techniques =
            byMapping: ->
                smPath = @getPaths()[@getFilenames().indexOf(path)]
                if smPath
                    smResolvedPath = Path.join @config.vendors.prefix, smPath
                else
                    false

            byComment: ->
                comment = content.match(R_SOURCE_MAP_COMMENT)
                if comment?
                    pathDir = Path.dirname(path)
                    mapPath = Path.join pathDir, comment[1]
                else
                    false

            byFilenameDotMap: ->
                # Need to go
                noMin = path.replace '.min', ''
                mapPath = "#{noMin}.map"
                if FS.statSync mapPath
                    mapPath
                else
                    false

            byFilenameMapDotPrefix: ->
                # Need to go
                noMin = path.replace '.min', ''
                [_, file, ext] = noMin.match(/^(.*)\.([^\.]+)$/)
                mapPath = "#{file}.map.#{ext}"
                if FS.statSync mapPath
                    mapPath
                else
                    false

        for name, technique of techniques
            try
                if _ = technique()
                    @log "Found sourceMap for #{path} with #{name}"
                    sourceMap = JSON.parse FS.readFileSync _, 'utf-8'
                    return sourceMap
            catch err
                @err err
        return _

    render: (content, path)->
        sourceMap = @findSourceMap(content, path)
        content = content.replace R_SOURCE_MAP_COMMENT, ''
        Q { content, sourceMap, path }

    vendorOrder: (path)->
        order = Number.MAX_VALUE
        @pattern().forEach (pattern, i)->
            order = i if minimatch path, pattern
        order

    getFilenames: ->
        Object
            .keys(@filelist)
            .filter (filename)=>
                # Check that the filename is the end of at least one file
                # in the pattern.
                filename in @pattern().map (_)-> _.substr(-filename.length)
            .sort (a, b)=>
                @vendorOrder(a) - @vendorOrder(b)

module.exports = VendorWatcher

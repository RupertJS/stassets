Q = require 'q'
FS = require 'fs'
Path = require 'path'
AssetWatcher = require '../Sourcemap'
minimatch = require 'minimatch'

R_SOURCE_MAP_COMMENT = ///
(?:/\*|//|\#) # Opening comment (css or js or coffee)
\#\ssourceMappingURL=([^\s]+) # URL
(?:\s+\*/)? # Optional close comment (css)
///

class VendorWatcher extends AssetWatcher
    constructor: ->
        @config.vendors or=
            js: []
            css: []
        @config.vendors.prefix or= './'
        unless @config.vendors.prefix.length? and @config.vendors.prefix.map?
            @config.vendors.prefix = [@config.vendors.prefix]
        @config = JSON.parse JSON.stringify @config # Quick clone hack
        @config.root = @config.vendors.prefix
        @config.noRoot = true
        @files = @getPaths()

        super()

    pattern: (patterns)->
        fullist = []
        for root in @config.vendors.prefix
            for pattern in patterns
                fullist.push Path.normalize "#{root}/#{pattern}"
        fullist

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
                if FS.existsSync mapPath
                    mapPath
                else
                    false

            byFilenameMapDotPrefix: ->
                # Need to go
                noMin = path.replace '.min', ''
                [_, file, ext] = noMin.match(/^(.*)\.([^\.]+)$/)
                mapPath = "#{file}.map.#{ext}"
                if FS.existsSync mapPath
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
                # @err err
        # Never returnd from techniques, this is the last ditch effort
        @log "Generating sourceMap for #{path}"

        return @buildSourcemap content, path

    render: (content, path)->
        sourceMap = @findSourceMap(content, path)
        if sourceMap and not sourceMap.sourcesContent
            # Try to find the original
            origPath = Path.join Path.dirname(path), sourceMap.sources[0]
            if FS.existsSync origPath
                sourceMap.sourcesContent = [
                    FS.readFileSync origPath, 'utf-8'
                ]
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

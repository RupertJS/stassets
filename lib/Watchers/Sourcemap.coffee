AssetWatcher = require './Asset'
convert = require 'convert-source-map'
combine = require 'combine-source-map'

class SourcemapWatcher extends AssetWatcher
    constructor: ->
        @files = @files.concat @files.map (_)-> "#{_}.map"
        super()

    handle: (req, res, next)->
        res.status(200).set('Content-Type', @type())
        if req.path.substr(-4) is '.map' and @hasMap
            res.send(@map)
        else
            res.set('SourceMap', req.path + '.map') if @hasMap
            res.send(@content)

    hapiHandle: (request, reply)->
        if request.path.substr(-4) is '.map' and @hasMap
            reply(@map).type('application/json')
        else
            reply = reply(@content).type(@type())
            reply.header('SourceMap', request.path + '.map') if @hasMap

    getPaths: -> @files
    concat: (_)->
        content = _.map((f)->f.content).join '\n'
        sourceMap = null

        try
            lastOffset = 0
            bundle = combine.create(@files[0])
            _.map (f)->
                comment = convert.fromObject(f.sourceMap).toComment()
                # + 1 for the '\n' in the join above
                newLines = (f.content.match(/\n/g)||[]).length + 1
                source = "#{f.content}\n#{comment}"
                sourceFile = f.sourceMap.sources[0]
                {source, sourceFile, newLines}
            .forEach (f, i)->
                offset = {line: lastOffset}

                lastOffset += f.newLines
                delete f.newLines

                bundle.addFile f, offset

            base64 = bundle.base64()
            sourceMap = convert.fromBase64(base64).toObject()
        catch err
            @log {warning: "Failed combining source maps.", err}
        {content, sourceMap}

    finish: (_ = {content: ''})->
        @printSuccess()
        @content = _.content
        @hasMap = _.sourceMap?
        @map = JSON.stringify _.sourceMap if @hasMap
        @_defer.resolve()

module.exports = SourcemapWatcher

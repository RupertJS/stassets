AssetWatcher = require './Asset'
convert = require 'convert-source-map'
combine = require 'combine-source-map'

class SourcemapWatcher extends AssetWatcher
    constructor: ->
        @files = @files.concat @files.map (_)-> "#{_}.map"
        super()

    handle: (req, res, next)->
        res.status(200).set('Content-Type', @type())
        if req.path.substr(-4) is '.map'
            res.send(@map)
        else
            res.set('SourceMap', req.path + '.map').send(@content)

    getPaths: -> @files
    concat: (_)->
        content = _.map((f)->f.content).join '\n'

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

        {content, sourceMap}

    finish: (_)->
        @printSuccess()
        @content = _.content
        @map = JSON.stringify _.sourceMap
        @_defer.resolve()

module.exports = SourcemapWatcher

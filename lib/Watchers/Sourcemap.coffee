AssetWatcher = require './Asset'

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

    getPaths: -> @files
    concat: (_)->
        content = _.map((f)->f.content).join '\n'

        lastOffset = 0
        sections = _
        .map (f)->
            offset = {line: lastOffset, column: 0}
            lastOffset += (f.content.match(/\n/g)||[]).length + 1
            {map: f.sourceMap, offset }
        .filter (f)->
            f.map

        sourceMap = {
            version: 3
            file: @files[0]
            sections
        }

        {content, sourceMap}

    finish: (_ = {content: ''})->
        @printSuccess()
        @content = _.content
        @hasMap = _.sourceMap?
        if @hasMap
          map = JSON.stringify _.sourceMap
          prefix = SourcemapWatcher.XSSI_PREFIX
          @map = prefix + map
        @_defer.resolve()

    failedRender: -> {content: '', sourceMap: null}

SourcemapWatcher.XSSI_PREFIX = ')]}\'\n'

module.exports = SourcemapWatcher

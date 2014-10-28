Path = require 'path'
VendorWatcher = require('./Vendor')
Generator = require('source-map').SourceMapGenerator
SourceNode = require('source-map').SourceNode
esprima = require 'esprima'

class VendorScriptWatcher extends VendorWatcher
    constructor: (@config)->
        @files = ['/vendors.js']
        @config.vendors or= {}
        @config.vendors.js or= []
        @config.vendors.jsMaps or= []
        super()

    pattern: -> super @config.vendors.js
    getMaps: -> @config.vendors.jsMaps
    type: -> "application/javascript"

    buildSourcemap: (content, path)->
        source = file = @pathpart path

        tokens = []
        generator = new Generator({file})
        try
            tokens = esprima.tokenize(content, {loc: yes})
        catch e
            tokens = [
                loc:
                    start:
                        line: 1
                        column: 0
                    end:
                        line: content.split('\n').length
                        column: 0
            ]

        tokens.forEach (token)->
            loc = token.loc.start
            original = {line: loc.line, column: loc.column}
            generated = {line: loc.line + 1, column: loc.column}
            mapping = {generated, original, source}
            if token.type is 'Identifier'
                mapping.name = token.value
            generator.addMapping mapping

        sourceMap = generator.toJSON()
        sourceMap.sourcesContent = [content]

        return sourceMap

module.exports = VendorScriptWatcher

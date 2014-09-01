Q = require 'q'
AssetWatcher = require './Watcher'
Loader = require './Loader'

class AssetBuilder extends AssetWatcher
    constructor: ->
        super()
        @_defer = Q.defer()
        @promise = @_defer.promise
        @content = ""

    encoding: -> 'utf-8'
    type: -> "application/javascript"
    handle: (req, res, next)->
        res.status(200).set('Content-Type', @type()).send(@content)

    hapi: (plugin)->
        @plugin = plugin
        @useHapi()
        for path in @getPaths()
            @plugin.route
                method: 'GET'
                path: path
                handler: (request, reply)=>
                    @hapiHandle request, reply

    hapiHandle: (request, reply)->
        reply(@content).type(@type())

    hash: -> require('sha1')(@content)

    ###
    The compile function orchestrates the load / render / concat loop.
    Unsurprisingly, there are three links in the promise chain. The first builds
    an array of `Loader`s, one for each file to load. The `Loader` does the fs
    to the source file, and resolves with that code and a reference to itself
    (for metadata). The second passes each `Loader`'s source to a subclass'
    `render` function, which can return either the rendered file, or a promise
    for the render. Finally, the list of render promises are joined and passed
    to the concatenator. The result of that step is the value assigned to
    `this.content`.
    ###
    compile: ->
        filenames = @getFilenames()

        readMap = filenames.map (_)=> (new Loader(_, @)).promise

        renderMap = readMap.map (_)=>
            d = Q.defer()
            _.catch ([__, loader])=>
                @printError "read `#{loader.path}`", @formatReadError __
                Q ''
            .then ([__, loader])=>
                @printStart loader
                try
                    d.resolve @render __, loader.path
                catch err
                    d.reject err
            d.promise
        Q.all(renderMap)
        .catch (__)=>
            @printError 'render', @formatRenderError __
            Q ''
        .then((_)=> Q @concat _)
        .catch (__)=>
            @printError 'concat', @formatConcatError __
        .then((_)=> @finish(_))
        .done()

        @

    render: (_, path)-> _
    concat: (_)-> _.join('\n')
    finish: (_)->
        @printSuccess()
        @content = _
        @emit 'Compiled', {name: @constructor.name, files: @getPaths()}
        @_defer.resolve()

    formatReadError: (error, loader)-> error
    formatRenderError: (error, loader)-> error
    formatConcatError: (error)-> error

module.exports = AssetBuilder

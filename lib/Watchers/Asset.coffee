fs = require 'fs'
Path = require 'path'
sha1 = require 'sha1'

Gaze = require('gaze').Gaze
minimatch = require 'minimatch' # TODO Remove after
                                # https://github.com/shama/gaze/issues/104
                                # gets resolved

class AssetWatcher
    constructor: ->
        @content = ""
        @filelist = {}

        unless @pattern? and @pattern instanceof Array
            throw new Error "No sane pattern, have #{@pattern}"

        @gaze = new Gaze @pattern

        @gaze.on 'error', (_)=> console.log _

        @gaze.on 'ready', =>
            @gaze.watched (err, matched = {})=>
                return console.log err if err
                for _, files of matched
                    files
                    .filter (filepath)=> # TODO Remove [shama/gaze/issues/104]
                        for pattern in @pattern
                            if minimatch filepath, pattern
                                return true
                        false
                    .forEach (filepath)=>
                        if fs.statSync(filepath).isFile()
                            @filelist[filepath] = yes
                @compile()
        @gaze.on 'added', (_)=> @add _
        @gaze.on 'deleted', (_) => @remove _
        @gaze.on 'changed', (_)=> @compile()

    add: (filepath)->
        @filelist[filepath] = yes
        @compile()

    remove: (filepath)->
        @filelist[filepath] = yes
        delete @filelist[filepath]
        @compile()

    type: -> "application/javascript"

    handle: (req, res, next)->
        res.status(200).set('Content-Type', @type()).send(@content)

    hash: ->
        sha1 @content

module.exports = AssetWatcher

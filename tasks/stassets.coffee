request = require 'supertest'
stassets = require '../lib/index.coffee'
express = require 'express'
Path = require 'path'
fs = require 'fs'
Q = require 'q'

module.exports = (grunt)->

    grunt.registerMultiTask 'stassets',
        'Launch a stassets server, wait for render, and save.',
        ->
            done = @async()
            options = @options
                stassets:
                    verbose: no // TODO Tie to Grunt
                    root: Path.resolve './test/assets'
                    vendors:
                        prefix: Path.resolve './bower_components'
                        js: [ 'angular/angular.js' ]
                        css: [ 'bootstrap/dist/css/*.css', '!*.min.css' ]
                dest: Path.resolve './tmp/stassets'
                files: [
                    'index.html'
                    'application.js'
                    'templates.js'
                    'vendors.js'
                    'vendors.css'
                    'all.css'
                    'screen.css'
                    'print.css'
                ]

            grunt.file.mkdir options.dest

            compiler = new stassets.Stassets options.stassets
            compiler.promise.catch done

            app = express()
            app.use (r, s, n)-> compiler.handle r, s, n

            getFile = (file)->
                defer = Q.defer()
                grunt.verbose.writeln "Starting request for #{file}..."
                request(app).get("/#{file}")
                .end (err, res)->
                    grunt.verbose.writeln "Finished request for #{file}..."
                    defer.reject err if err
                    defer.reject res if res.status isnt 200
                    grunt.file.write "#{options.dest}/#{file}", res.text
                    defer.resolve()
                defer.promise

            writeFiles = ->
                grunt.verbose.writeln 'Stassets compiled all files!'
                promises = options.files.map getFile
                Q.all(promises).then(done, done)

            compiler.promise.then writeFiles, (_)->done(_)

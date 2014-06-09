should = require('chai').should()
fs = require 'fs'
request = require 'supertest'
express = require 'express'
stasset = require './index'

app = express()

app.use(stasset({root: "#{__dirname}/../test/assets"}))

loadFixture = (fixture)->
    fs.readFileSync(
        "#{__dirname}/../test/fixtures/#{fixture}"
    ).toString('utf-8').replace(/\n$/m, '')

describe "DS Asset Middleware", ->
    before (done)->
        # Let the watchers compile
        setTimeout done, 50

    describe "Index", ->
        it 'renders jade to html', (done)->
            request(app)
            .get('/index.html')
            .set('Accept', 'text/html')
            .expect(200)
            .expect('Content-Type', 'text/html; charset=utf-8')
            .expect(loadFixture('index.html'))
            .end(done)

        it 'injects fingerprints', ->

    describe "Templates", ->
        it 'renders jade to JS', (done)->
            request(app)
            .get('/templates.js')
            .set('Accept', 'application/javascript')
            .expect(200)
            .expect('Content-Type', 'application/javascript; charset=utf-8')
            .expect(loadFixture('templates.js'))
            .end(done)

        it 'inserts into correct modules', ->

    describe "App Styles", ->
        it 'renders Stylus with Nib', ->

        it 'renders all, screen, and print', ->

    describe "Application", ->
        it 'loads application code', (done)->
            request(app)
            .get('/application.js')
            .set('Accept', 'application/javascript')
            .expect(200)
            .expect('Content-Type', 'application/javascript; charset=utf-8')
            .expect(loadFixture('application.js'))
            .end(done)

        it 'ignores test code', ->

    describe "Vendors", ->

    describe "Vendor Styles", ->

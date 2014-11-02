should = require('chai').should()
fs = require 'graceful-fs'
request = require 'supertest'
express = require 'express'
stasset = require './index'
shasum = require('shasum')

app = express()

middleware = stasset(require("#{__dirname}/../test/server/config"))
app.use middleware

sum = (expected = '')->
    expectedSum = shasum(expected)
    (res)->
        if process.env.DEBUG
            try
                expected.should.equal(res.text)
            catch e
                console.log e
        expected.length.should.equal res.text.length, 'Lengths match.'
        expectedSum.should.equal(shasum(res.text or ''), 'Sums match.')
        false

loadFixture = (fixture)->
    sum(fs.readFileSync("#{__dirname}/../test/fixtures/#{fixture}", 'utf-8'))

checkMap = (fixture)->
    src = fs.readFileSync("#{__dirname}/../test/fixtures/#{fixture}", 'utf-8')
    expected = JSON.parse(src.substr(4))

    (res)->
        mapSrc = res.text.substr(4)
        map = JSON.parse(mapSrc)
        map.sections.length.should.equal(
            expected.sections.length,
            'Sourcemap sections match.'
        )
        false

describe "Sstassets Middleware", ->
    before (done)->
        # Let the watchers compile
        middleware.promise.fin done

    describe "Index", ->
        it 'renders jade to html', (done)->
            request(app)
            .get('/index.html')
            .set('Accept', 'text/html')
            .expect(200)
            .expect('Content-Type', /html; charset=utf-8/)
            .expect(loadFixture('index.html'))
            .end(done)

        it.skip 'injects fingerprints', ->

    describe "Templates", ->
        it 'renders jade to JS', (done)->
            request(app)
            .get('/templates.js')
            .set('Accept', 'application/javascript')
            .expect(200)
            .expect('Content-Type', /javascript/)
            .expect(loadFixture('templates.js'))
            .end(done)

        it.skip 'inserts into correct modules', ->

        it 'generates source maps', (done)->
            request(app)
            .get('/templates.js.map')
            .expect(200)
            .expect(loadFixture('templates.js.map'))
            .end(done)

    describe "App Styles", ->
        it 'renders Stylus with Nib', (done)->
            request(app)
            .get('/screen.css')
            .expect(200).expect('Content-Type', /css/)
            .expect(loadFixture('screen.css'))
            .end(done)

        it 'renders all', (done)->
            request(app)
            .get('/all.css')
            .expect(200).expect('Content-Type', /css/)
            .expect(loadFixture('all.css'))
            .end(done)

        it 'renders print', (done)->
            request(app)
            .get('/print.css')
            .expect(200).expect('Content-Type', /css/)
            .expect(loadFixture('print.css'))
            .end(done)

        it 'generates source maps', (done)->
            request(app)
            .get('/all.css.map')
            .expect(200)
            .expect(checkMap('all.css.map'))
            .end(done)

    describe "Application", ->
        it 'loads application code', (done)->
            request(app)
            .get('/application.js')
            .set('Accept', 'application/javascript')
            .expect(200)
            .expect('Content-Type', /javascript/)
            .expect(loadFixture('application.js'))
            .end(done)

        it.skip 'ignores test code', ->
            # Not directly tested, as the loadFixture above would fail.

        it 'references a sourcemap', (done)->
            request(app)
            .get('/app.js')
            .expect(200)
            .expect('SourceMap', '/app.js.map')
            .end(done)

        it 'generates a source map', (done)->
            request(app)
            .get('/app.js.map')
            .expect(200)
            .expect(checkMap('application.js.map'))
            .end(done)

    describe "Vendors", ->
        it 'loads the vendors js', (done)->
            request(app)
            .get('/vendors.js')
            .set('Accept', 'application/javascript')
            .expect(200)
            .expect('Content-Type', /javascript/)
            .expect('SourceMap', /vendors\.js\.map/)
            .expect(loadFixture('vendors.js'))
            .end(done)

        it 'loads as good a sourcemap as possible', (done)->
            request(app)
            .get('/vendors.js.map')
            .expect(200)
            .expect(loadFixture('vendors.js.map'))
            .end(done)

        describe "Styles", ->
            it 'loads a joined stylesheet', (done)->
                request(app)
                .get('/vendors.css')
                .expect(200)
                .expect('Content-Type', /css/)
                .expect('SourceMap', /vendors\.css\.map/)
                .expect(loadFixture('vendors.css'))
                .end(done)

            it 'loads as good a sourcemap as possible', (done)->
                request(app)
                .get('/vendors.css.map')
                .expect(200)
                .expect(checkMap('vendors.css.map'))
                .end(done)

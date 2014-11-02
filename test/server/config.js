module.exports = {
    verbose: true,
    root: [__dirname + "/../assets", __dirname + "/../cascade"],
    scripts: {
        types: [
            'main', 'provider', 'filter', 'service', 'controller', 'directive'
        ]
    },
    vendors: {
        prefix: [__dirname + "/vendors"],
        js: [ 'lib.js' ],
        jsMaps: [ 'lib.js.map' ],
        css: [ 'lib.css' ],
        cssMaps: [ 'lib.css.map' ]
    }
}

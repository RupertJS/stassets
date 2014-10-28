require('coffee-script/register')
var express = require('express')
var stasset = require('../../lib/index')

var app = express();

app.use(stasset({
    verbose: true,
    root: [__dirname + "/../assets", __dirname + "/../cascade"],
    vendors: {
        prefix: __dirname + "/../../node_modules",
        js: [
            'angular-builds/angular.min.js',
            'angular-builds/angular-animate.min.js',
            'moment/min/moment.min.js'
        ],
        jsMaps: [ 'angular/angular.min.js.map' ],
        css: [ 'bootstrap/dist/css/bootstrap.css' ],
        cssMaps: [ 'bootstrap/dist/css/bootstrap.css.map' ]
    }
}));
app.listen(8989);

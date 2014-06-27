require('coffee-script/register')
var express = require('express')
var stasset = require('../../lib/index')

var app = express();

app.use(stasset({
    verbose: true,
    root: __dirname + "/../assets",
    vendors: {
        prefix: __dirname + "/../../bower_components",
        js: [ 'angular/angular.js' ],
        css: [ 'bootstrap/dist/css/bootstrap.css' ]
    }
}));
app.listen(8989);

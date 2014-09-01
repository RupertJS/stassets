var Hapi = require('hapi');
var Stasset = require('../../lib/index');
var Good = require('good');

var server = new Hapi.Server('localhost', 8080);

server.pack.register([
    {
        plugin: Good,
        options: {
            subscribers: {
                'console': ['ops', 'request', 'log', 'error']
            }
        }
    },
    {
        plugin: Stasset,
        options: {
            verbose: true,
            root: [__dirname + "/../assets", __dirname + "/../cascade"],
            vendors: {
                prefix: __dirname + "/../../node_modules",
                js: [ 'angular-builds/angular.min.js' ],
                jsMaps: [ 'angular/angular.min.js.map' ],
                css: [ 'bootstrap/dist/css/bootstrap.css' ],
                cssMaps: [ 'bootstrap/dist/css/bootstrap.css.map' ]
            }
        }
    }
], function(err){
    if(err){
        console.error('Failed to load plugin:', err);
    } else {
        server.start();
    }
});

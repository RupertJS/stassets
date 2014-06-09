require('coffee-script/register')
var express = require('express')
var stasset = require('../../lib/index')

var app = express();

app.use(stasset({root: __dirname + "/../assets"}));
app.listen(8989);

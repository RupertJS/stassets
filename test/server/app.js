require('coffee-script/register')
var express = require('express')
var stasset = require('../../lib/index')

var app = express();

app.use(stasset(require('./config')));
app.listen(8989, function(err){
  if(err){
    return console.error(err);
  }
  console.log("Listening http://localhost:8989");
});

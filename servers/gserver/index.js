/***********
G Server
***********/
/*
 * A server for hosting interactive user app / feeding it to processing via TCP protocol.
 *
 * TCP: http://localhost:45010
 * APP: http://localhost:3000
 *
 * Copyright Chris Malcolm, NBBJ digital 2018
 * http://www.nbbj.com/about/digital-practice/
 *
 */


var util = require('util');
var net = require('net');
var bodyParser  =  require("body-parser");
const express = require('express');
const app = express();
var sketchString = "";

app.use(express.static(__dirname + '/public'));
app.use(bodyParser.urlencoded({ extended: false }));
app.use(bodyParser.json());

var APP_PORT = 3000;
var TELNET_PORT = 45010;
var TELNET_HOST="localhost";

app.post('/sendSketch', (req, res) => {
  sketchString = req.body.sketch;
  var sketch = JSON.parse(req.body.sketch);
  console.log("hello recieved sketch", sketch);
});

app.get('/', (req, res) => {

  console.log("hello..");
  res.render('index');

});

/* TCP FOR PROCESSING */
var server = net.createServer(function(socket) {
	socket.write('Echo server\r\n');
	socket.pipe(socket);
	  console.log('client connected');
	  
    socket.on('end', () => {
	    clearInterval(mainInterval);
	  });
    
  //just added
  socket.on("error", (err) => {
    console.log("Caught socket error: ");
    console.log(err.stack);
    clearInterval(mainInterval);
  });

	mainInterval = setInterval(function(){
    if (sketchString!=""){
      socket.write(sketchString+"\n");
      sketchString="";
    }
	},1000);
});


server.on('end', function (e) {
    console.log('Aerror occurred..',e);
    setTimeout(function () {
      server.close();
      server.listen(TELNET_PORT, TELNET_HOST);
    }, 1000);
  });

server.on('close', function (e) {
    console.log('Aerror occurred..',e);
    setTimeout(function () {
      server.close();
      server.listen(TELNET_PORT, TELNET_HOST);
    }, 1000);
  });


server.on('error', function (e) {
    console.log('Aerror occurred..',e);
    setTimeout(function () {
      server.close();
      server.listen(TELNET_PORT, TELNET_HOST);
    }, 1000);
  });

server.listen(TELNET_PORT, TELNET_HOST);
app.listen(APP_PORT, () => console.log('App listening on port 3000!'))
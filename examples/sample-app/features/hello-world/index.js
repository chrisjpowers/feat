var express, feat, server;
feat = require("feat");
express = require("express");

exports.server = server = express();

server.configure(function() {
  server.set("views", "" + __dirname + "/views");
  server.use(express.static("" + __dirname + "/public"));
});

server.get("/hello", function(req, res) {
  res.send("<h1>Hello World!</h1>");
});

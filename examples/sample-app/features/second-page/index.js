var express, feat, server;

feat = require("feat");

express = require("express");

exports.server = server = express();

server.get("/second-page", function(req, res) {
  var out = "<h1>Second Page</h2>";
  if (feat.isEnabled("hello-world")) {
    out = out + "<p><a href='/hello'>Go to Hello World</a></p>";
  }
  res.send(out);
});

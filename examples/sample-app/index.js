var feat = require("feat"),
    express = require("express"),
    app = express(),
    port = process.env.PORT || 8080;

feat.persistence.use("file");

app.use(feat.middleware());
app.use(feat.gui());
app.listen(port);
console.log("Listening on port " + port);

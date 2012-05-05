express = require "express"

module.exports = ->
  feat = require "feat"
  app = express.createServer()
  app.use express.bodyParser()
  app.use "/features/gui", express.static("#{__dirname}/client")

  app.configure ->
    app.set 'views',  "#{__dirname}/views"
    app.set 'view engine', 'jade'

  app.get "/features", (req, res) ->
    res.render "index.jade", layout: false

  app.get "/features.json", (req, res) ->
    res.send feat.features()

  app.post "/features.json", (req, res) ->
    res.send feat.features(req.body)

  app

express = require "express"

module.exports = ->
  feat = require "../../.."
  app = express()
  app.use express.bodyParser()
  app.use "/features", express.static("#{__dirname}/client")

  app.get "/features/features.json", (req, res) ->
    res.send feat.features()

  app.post "/features/features.json", (req, res) ->
    res.send feat.features(req.body)

  app

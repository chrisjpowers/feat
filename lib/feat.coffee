_ = require "underscore"
fs = require "fs"
pathLib = require "path"
express = require "express"
EventEmitter = require("events").EventEmitter

middleware = express()

config = dir = null
module.exports = feat = new EventEmitter

updateFeatures = (newFeatures) ->
  features = persistence.get()
  changed = false
  for name, active of newFeatures
    if active == "true" then active = true
    if active == "false" then active = false
    if features[name] != active
      changed = true
      msg = "#{name}:#{if active then 'on' else 'off'}"
      feat.emit msg
    features[name] = active
  persistence.set features if changed
  features

feat.commands = require "./plugins/commands"
feat.gui = require "./plugins/gui"
feat.persistence = persistence = require("./plugins/persistence")()

feat.middleware = (opts = {}) ->
  dir = opts.dir || "#{process.cwd()}/features"

  fs.readdir dir, (err, files) ->
    features = persistence.get()
    for n in files
      do ->
        name = n
        features[name] ?= false
        mod = require "#{dir}/#{name}"
        if mod.server
          middleware.use (req, res, next) ->
            if persistence.get()[name]
              mod.server.handle(req, res, next)
            else
              next()
    updateFeatures features

  middleware

feat.features = (newFeatures) ->
  if newFeatures
    updateFeatures newFeatures
  else
    persistence.get()

feat.isEnabled = (name) ->
  !!persistence.get()[name]

_ = require "underscore"
fs = require "fs"
pathLib = require "path"
express = require "express"
EventEmitter = require("events").EventEmitter
commands = require "./commands"

middleware = express()

features = {}
config = dir = null
module.exports = feat = new EventEmitter

feat.runCommand = (name, args=[]) ->
  if command = commands[name]
    command.apply this, args
  else
    console.log "Sorry, the '#{name}' command is not valid."
    command.help()

updateFeatures = (newFeatures) ->
  changed = false
  for name, active of newFeatures
    if active == "true" then active = true
    if active == "false" then active = false
    if features[name] != active
      changed = true
      msg = "#{name}:#{if active then 'on' else 'off'}"
      feat.emit msg
    features[name] = active
  fs.writeFile config, JSON.stringify(features) if changed

feat.gui = require "./plugins/gui"

feat.middleware = (opts = {}) ->
  dir = opts.dir || "#{process.cwd()}/features"
  config = opts.config || "#{process.cwd()}/.features.json"

  fs.readFile config, (err, data) ->
    unless err
      updateFeatures JSON.parse(data)

  fs.readdir dir, (err, files) ->
    for n in files
      do ->
        name = n
        features[name] ?= false
        console.log "Loading", name
        mod = require "#{dir}/#{name}"
        if mod.server
          middleware.use (req, res, next) ->
            if features[name]
              mod.server.handle(req, res, next)
            else
              next()

  # This sucks, we need to figure out how to use fs.watch
  fs.watchFile config, (curr, prev) ->
    if "#{curr.mtime}" != "#{prev.mtime}"
      fs.readFile config, (err, data) ->
        newFeatures = JSON.parse data
        updateFeatures newFeatures

  middleware

feat.features = (newFeatures) ->
  if newFeatures
    updateFeatures newFeatures
  features

feat.isEnabled = (name) ->
  !!features[name]

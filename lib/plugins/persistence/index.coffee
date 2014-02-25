fs = require "fs"
_ = require "underscore"

module.exports = ->
  persistor = null

  persistenceAdapter =
    use: (name, args...) ->
      persistor?.stop?()
      persistor = persistors[name](args...)
      persistor.start?()
    get: ->
      _.clone persistor.get()
    set: (data) ->
      persistor.set(data)

  persistenceAdapter.use "memory"
  persistenceAdapter

persistors =
  memory: ->
    cache = {}

    get: ->
      cache

    set: (data) ->
      cache = data

    stop: ->
      cache = {}

  file: (path) ->
    path ?= "#{process.cwd()}/.features.json"
    cache = {}

    persistence =
      get: ->
        cache

      set: (data) ->
        cache = data
        fs.writeFile path, JSON.stringify(data)

      start: ->
        readConfig = ->
          # Having some race condition when using async, using sync for now, need to fix
          try
            data = fs.readFileSync path
            cache = JSON.parse(data.toString())
          catch e
            cache = {}

        fs.watchFile path, (curr, prev) ->
          readConfig() if "#{curr.mtime}" != "#{prev.mtime}"

        readConfig()

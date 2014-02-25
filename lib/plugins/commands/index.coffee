exports.run = (name, args...) ->
  if command = commands[name]
    command(args...)
  else
    console.log "Sorry, the '#{name}' command is not valid."
    commands.help()

commands =
  help:  ->
    console.log """
                Available feat commands:
                -----------------------
                feat add featureName - Bootstrap a new feature in your /features directory
                feat disable featureName - Turns a feature off
                feat enable featureName - Turns a feature on
                feat help - See this message
                feat start [feature] - Run the server for a given feature (or `npm start` if omitted)
                feat test [feature] - Run mocha tests for the given feature (or all if omitted)

                """

  add: (name) ->
    coffee = require "coffee-script"
    fs = require "fs"
    mkdirp = require "./mkdirp"
    dir = "#{process.cwd()}/features/#{name}"
    mkdirp.sync "#{dir}/public"
    mkdirp.sync "#{dir}/views"
    mkdirp.sync "#{dir}/spec"

    packPath = "#{process.cwd()}/package.json"
    if fs.existsSync packPath
      pack = require packPath
      useCoffee = pack.dependencies["coffee-script"]?
    else
      useCoffee = false

    indexCode = fs.readFileSync("#{__dirname}/templates/add/index.coffee.tmpl").toString()
    indexCode = indexCode.replace /\$name/g, name

    if useCoffee
      fs.writeFileSync "#{dir}/index.coffee", indexCode
    else
      fs.writeFileSync "#{dir}/index.js", coffee.compile(indexCode, bare: true)

    updateStatus name, true
    console.log "Added and enabled ./features/#{name}"

  enable: (feature) ->
    updateStatus feature, true

  disable: (feature) ->
    updateStatus feature, false

  start: (feature = null) ->
    spawn = require("child_process").spawn
    if feature
      dir = "#{process.cwd()}/features/#{feature}"
      mod = require dir
      app = mod.server
      if app
        port = process.env.PORT || 8228
        app.listen port
        console.log "Server is running feature `#{feature}` on port #{port}"
      else
        console.log "Unable to run the server -- does the `#{feature}` module export a `server` function?"
    else
      console.log "No feature specified, running `npm start`...\n"
      pack = require "#{process.cwd()}/package.json"
      if pack.scripts?.start?
        cmd = pack.scripts.start.split " "
        testServer = spawn cmd.shift(), cmd
        testServer.stdout.pipe process.stdout
        testServer.stderr.pipe process.stdout
        testServer.on "exit", (code) -> process.exit code
        process.on "exit", ->
          testServer.kill "SIGHUP"
      else
        console.log "Unable to run `npm start` -- please add a `scripts.start` command to package.json"

  test: (feature = null) ->
    fs = require "fs"
    spawn = require("child_process").spawn
    glob = require "glob"
    _  = require "underscore"

    port = process.env.PORT || 8228
    process.env.NODE_ENV = 'test'
    testServer = null

    if feature
      dir = "#{process.cwd()}/features/#{feature}"
      mod = require dir
      app = mod.server
      if app
        app.listen port
        console.log "Test server is running on port #{port}"
      else
        console.log "Unable to run the test server -- does the `#{feature}` module export a `server` function?"
    else
      dir = "#{process.cwd()}/features/**"
      feature = "**"
      newEnv = {}
      _.extend newEnv, process.env, PORT: port

      pack = require "#{process.cwd()}/package.json"
      cmd = pack.scripts.start.split " "
      testServer = spawn cmd.shift(), cmd, cwd: "#{process.cwd()}", env: newEnv
      console.log "Test server is running on port #{port}"

    files = glob.sync("#{dir}/spec/*spec.coffee")
      .concat(glob.sync("#{dir}/spec/*spec.js"))
      .concat(glob.sync("#{dir}/test/*test.coffee"))
      .concat(glob.sync("#{dir}/test/*test.js"))

    requires = ["coffee-script"]
    requireStr = _.map(requires, (r) -> "-r #{r}").join " "

    cmd = "mocha #{requireStr} -u bdd --compilers coffee:coffee-script --ignore-leaks".split(" ").concat(files)
    console.log cmd.join(" ")
    testProc = spawn cmd.shift(), cmd

    testProc.stdout.on 'data', (data) ->
      process.stdout.write data

    testProc.stderr.on 'data', (data) ->
      process.stderr.write data

    testProc.on 'exit', (code) ->
      console.log "All done!"
      testServer.kill "SIGHUP" if testServer
      process.exit code

updateStatus = (feature, status) ->
  fs = require "fs"
  features = {}

  configPath = "#{process.cwd()}/.features.json"
  if fs.existsSync(configPath)
    features = JSON.parse fs.readFileSync(configPath)

  features[feature] = status
  fs.writeFileSync configPath, JSON.stringify(features)


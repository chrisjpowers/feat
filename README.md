# Feat

Successfully organizing your source code as your app grows can be quite a *feat*.
That's why I wrote **Feat**.

Feat is a tool for modularly organizing your Node.js code by feature rathan than taxonomy. 
Rails-style `model`, `controller`, `view`, etc. directories bloat uncontrollably
over time, so Feat puts all the code that pertains to a given feature in its
own directory. Every file that has to do with the given feature is colocated,
making it easy find your source code. Your file structure grows horizontally
rather than vertically, leveraging feature names to add an extra layer of
context to the code it contains.

Additionally, Feat allows you to easily toggle your features on and off without
having to restart your server! This gives you built-in dynamic feature rollout
functionality and can even help you A/B test your features.

*Disclaimer: Feat's API is still in flux, so breaking changes may occur.*

## Installation

Install Feat as a global `npm` package so that you can use the `feat` command anywhere:

```bash
npm install -g feat
```

On the command line, `cd` to a Node.js project and use `feat add` to add a feature:

```bash
cd /path/to/myproject
feat add first-feature
```

This will add a `./features/first-feature` directory to your project. It also
will add `./features.json` where it will persist your current features configuration.
You can use this command to add additional features, or simply add your own
folders to the `./features` directory.

## Usage

### Middleware

First you need to add `feat.middleware()` to your Connect-compatible server:

```javascript
var feat = require("feat"),
    express = require("express"),
    app = express.createServer();

app.use(feat.middleware());
app.listen(8080);
```

### Feature Servers

If you look in `./features/first-feature/index.js` you will see that by
default it creates an Express server and exports it as `exports.server`.
When you boot your app up, Feat will wire up the servers of all enabled
features, leaving out the disabled features.

Here's a trivial example of a feature's server:

```javascript
// ./features/first-feature/index.js
var feat = require("feat"),
    express = require("express");

var server = exports.server = express.createServer();

server.get("/foo", function(req, res) {
  res.send("bar");
});
```

### Enabling/Disabling Features

If you start your server and visit `/foo` you will see the server respond
with "bar" because new features are turned on by default. To disable a feature,
use `feat disable`:

```bash
feat disable first-feature
```

Now if you visit `/foo` you should should not see a response. To turn the
feature back on, use `feat enable`:

```bash
feat enable first-feature
```

*NOTE: Features can be enabled and disabled "hot" without restarting your server!*

### Feature Events

While it should be a goal to keep features as detached from one another as
possible, clearly there will points of interaction that will have to be
setup when a feature is turned on and torn down when a feature is turned off.
It is a good practice to have features offer services to other features to
isolate and control the interactions. 

For example, let's say that we have a
`navigation` feature that manages the links in our site's nav. If our
`first-feature` needs to display a link in the navigation, it should only do
so when it is active. If it is deactivated, it needs to remove its link
from the navigation.

The `feat` object is an `EventEmitter` that emits events when features are
turned on and off. Here is how we could handle our navigation:

```javascript
// ./features/first-feature/index.js
var feat = require("feat"),
    express = require("express"),
    nav = require("../navigation");

var server = exports.server = express.createServer();

server.get("/foo", function(req, res) {
  res.send("bar");
});

feat.on("first-feature:on", function() {
  nav.add("/foo", "Foo");
});

feat.on("first-feature:off", function() {
  nav.remove("/foo");
});
```

Assuming that the `navigation` feature exported the `add` and `remove`
functions, we would be able to use them in this way to ensure our nav
is only present when this feature is turned on.

### Running an Isolated Feature Server

As an app grows in size, it can be useful in development to run a server
with your feature but without the rest. Feat supports this with the `start`
command:

```bash
feat start first-feature
```

Without a feature name, `feat start` runs whatever command you have for
`npm start` in your `package.json` file.

### Running Isolated Feature Specs

Similarly, running specs for a single feature is supported:

```bash
feat test first-feature
```

Feat assumes your feature directory has either a `spec` or `test` directory
with an optional `spec-helper.js` or `test-helper.js` file and tests that
use a *test.js or *spec.js naming convention. *NOTE: Coffeescript files
will also work automatically.*

`feat test` runs your feature's server at `localhost:8228` by default, adding
`{ENV: "test"}` to `process.env`. You can specify a custom port if needbe by
setting the `PORT` environment variable when you start `feat test`.

Running `feat test` without a feature name will run your server with `npm test`
and load all your features' tests.

## Plugins

### GUI

While enabling/disabling features from the command line works, it may be nice
to have a GUI for easily managing feature state in development and testing.
Feat ships with a GUI middleware that you can add to your server stack:

```javascript
var feat = require("feat"),
    express = require("express"),
    app = express.createServer();

app.use(feat.middleware());
if(process.env.ENV === "development") {
  app.use(feat.gui());
}
app.listen(8080);
```

There is currently *no authentication* built into the GUI, so it's important
that you do not deploy it to a production environment. One interesting
possibility is to create a "gui" feature that uses this middleware, that
way you are able to turn it on and off on the fly!

## Todos

Right now this organization strategy is experimental and I haven't actually
built out a project with it yet to validate whether or not it's effective.
I am actively looking for feedback and ideas about what works, what doesn't
and what is missing!

* Add code examples
* Build some apps with Feat to validate/invalidate the approach.
* Explore using Feat for graduated feature rollouts.
* Explore using Feat to A/B test features.
* Evaluate `feat test` and `feat server` -- are they useful?
* Evaluate on-the-fly feature switching -- is it worth the cost?
* Improve the GUI plugin
* Use something better than `fs.watchFile` to watch for changes to `features.json`

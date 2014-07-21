# stassets

## A Static Asset Compiler

---

Compiling is so blase. Let it just happen.

Stassets is an express middleware for keeping your browser code up to date and
ready to serve at a moment's notice. It watches your client directory structure,
and performs the build steps in memory. When you ask for your files, they've
already been compiled. Life is easy.

stassets also minimizes the number of files you will transfer - it breaks the
project into

```
.
├── index.html
├── application.js
├── templates.js
├── all.css
├── print.css
├── screen.css
├── vendors.css
└── vendors.js
```

And with a basic `index.jade` looking like

```jade
doctype html
html(ng-app="stassets.main")
    head
        title Test Fixture

        link(rel="stylesheet", href="vendors.css")

        link(rel="stylesheet", href="all.css")
        link(rel="stylesheet", href="screen.css", media="screen")
        link(rel="stylesheet", href="print.css", media="print")
body
    main

    script(src="vendors.js")
    script(src="templates.js")
    script(src="application.js")
```

your project is 7 files.

## Usage

stassets is built as an express middleware. With the default project layout,
the easiest server looks like this:

```javascript
var express = require('express')
var app = express();

var stasset = require('stasset')
app.use(stasset({
    // The client directory is relative to this app.js file
    root: __dirname + "/client"
    // My vendors are loaded with bower, which is a directory up from here.
    vendors: {
        prefix: __dirname + "/../bower_components",
        // These files will be concatenated in order.
        // All this uses is angular and bootstrap, but these can grow as large
        // as you need.
        js: [ 'angular/angular.js' ],
        css: [ 'bootstrap/dist/css/*' ]
    }
}));


app.listen(8989);

```

## Recommended Layout

Everything you know about project structure is wrong.

You should not group your files by `controller`, `model`, and `template`.

You should not let the computer and framework dictate backwards logic.

You need to work logically.

Group your code by component. It looks like this:

```
.
├── Gruntfile.coffee
├── index.jade
├── main
│   ├── all.styl
│   ├── footer
│   │   ├── directive.coffee
│   │   ├── template.jade
│   │   └── test.coffee
│   ├── login
│   │   ├── all.styl
│   │   ├── directive.coffee
│   │   ├── template.jade
│   │   └── test.coffee
│   ├── main.coffee
│   ├── nav
│   │   ├── directive.coffee
│   │   ├── template.jade
│   │   └── test.coffee
│   ├── print.styl
│   ├── screen.styl
│   └── test.coffee
├── scavenge
│   ├── gradebook
│   │   ├── directive.coffee
│   │   ├── service.coffee
│   │   ├── service.mock.coffee
│   │   ├── service.test.coffee
│   │   └── template.jade
│   ├── hunts
│   │   ├── all.styl
│   │   ├── directive.coffee
│   │   ├── directive.test.coffee
│   │   ├── edit
│   │   │   ├── directive.coffee
│   │   │   ├── template.jade
│   │   │   └── test.coffee
│   │   ├── service.coffee
│   │   ├── service.mock.coffee
│   │   ├── service.test.coffee
│   │   └── template.jade
│   ├── leaders
│   │   ├── all.styl
│   │   ├── directive.coffee
│   │   ├── template.jade
│   │   └── test.coffee
│   ├── students
│   │   ├── directive.coffee
│   │   ├── screen.styl
│   │   ├── service.coffee
│   │   ├── template.jade
│   │   └── test.coffee
│   └── submit
│       ├── controller.coffee
│       ├── controller.test.coffee
│       ├── directive.coffee
│       ├── directive.test.coffee
│       ├── grading
│       │   ├── controller.coffee
│       │   ├── directive.coffee
│       │   ├── screen.styl
│       │   └── template.jade
│       ├── screen.styl
│       ├── service.coffee
│       ├── service.mock.coffee
│       ├── service.test.coffee
│       └── template.jade
├── stylus
│   └── definitions
│       ├── mixins.styl
│       └── variables.styl
├── tools
│   └── render.coffee
└── util
    ├── fileInput
    │   ├── directive.coffee
    │   ├── service.coffee
    │   └── test.coffee
    └── thsort
        ├── directive.coffee
        ├── screen.styl
        └── template.jade
```

This is the client (in browser, Angular) codebase for a medium sized project,
that manages a gradebook of student programming submissions. Notice that the
controllers, templates, and tests are all next to one another. Don't drive five
directories up and three over to get to a file for the same component. That's
just crazy.

Stassets understands this directory layout, but can be configured to any other
layout.

## Cascading File System

`stassets` has the concept of a Cascading File System. By creating a similar
directory structure in several root directories, `stassets` users can quickly
and easily implement a themeing or plugin system. To generate a cascading file
system, `stassets` joins a list of root directories with a set of file patterns.
Files in each root directory matching a pattern are joined, with files in higher
priority root directories overwriting those with lower priority.

## Roadmap

* Allow plugin dependencies - let index.html inject hashes of other files.
* Testing integration (karma)
* Static static assets
    * Fonts
    * Images
* Utilities
    * Configurable logging
* Ease configuration
    * Configure patterns at runtime
    * Document Asset Watcher Extension

## Changelog
* **0.2.1** *2014-07-21* Replaced Gaze with Sane.
* **0.2.0** *2014-07-19* Implements Cascading File System.
* **0.1.4** *2014-06-16* Includes Grunt task to save compiled assets to disk,
for pure static server (also great for tests). *This is likely to move to
grunt-stassets in the very near future!*
* **0.1** *2014-06-12* Understands the basic project structure. Works great for
rapid development.

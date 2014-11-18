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

Group your code by component. It looks like this:

```
.
├── Gruntfile.coffee
├── index.jade
├── main
│   ├── all.styl
│   ├── footer
│   │   ├── footer-directive.coffee
│   │   ├── footer-template.jade
│   │   └── footer_test.coffee
│   ├── login
│   │   ├── login-all.styl
│   │   ├── login-directive.coffee
│   │   ├── login-template.jade
│   │   └── login_test.coffee
│   ├── main.coffee
│   ├── nav
│   │   ├── nav-directive.coffee
│   │   ├── nav-template.jade
│   │   └── nav_test.coffee
│   ├── main-print.styl
│   ├── main-screen.styl
│   └── main_test.coffee
├── scavenge
│   ├── gradebook
│   │   ├── gradebook-directive.coffee
│   │   ├── gradebook-service.coffee
│   │   ├── gradebook-service_mock.coffee
│   │   ├── gradebook-service_test.coffee
│   │   └── gradebook-template.jade
│   ├── hunts
│   │   ├── hunts-all.styl
│   │   ├── hunts-directive.coffee
│   │   ├── hunts-directive_test.coffee
│   │   ├── edit
│   │   │   ├── hunts-edit-directive.coffee
│   │   │   ├── hunts-edit-template.jade
│   │   │   └── hunts-edit_test.coffee
│   │   ├── hunts-service.coffee
│   │   ├── hunts-service_mock.coffee
│   │   ├── hunts-service_test.coffee
│   │   └── hunts-template.jade
│   ├── leaders
│   │   ├── leaders-all.styl
│   │   ├── leaders-directive.coffee
│   │   ├── leaders-template.jade
│   │   └── leaders_test.coffee
│   ├── students
│   │   ├── students-directive.coffee
│   │   ├── students-screen.styl
│   │   ├── students-service.coffee
│   │   ├── students-template.jade
│   │   └── students_test.coffee
│   └── submit
│       ├── submit-controller.coffee
│       ├── submit-controller_test.coffee
│       ├── submit-directive.coffee
│       ├── submit-directive_test.coffee
│       ├── grading
│       │   ├── submit-grading-controller.coffee
│       │   ├── submit-grading-directive.coffee
│       │   ├── submit-grading-screen.styl
│       │   └── submit-grading-template.jade
│       ├── submit-screen.styl
│       ├── submit-service.coffee
│       ├── submit-service_mock.coffee
│       ├── submit-service_test.coffee
│       └── submit-template.jade
├── stylus
│   └── definitions
│       ├── mixins.styl
│       └── variables.styl
└── util
    ├── fileInput
    │   ├── fileInput-directive.coffee
    │   ├── fileInput-service.coffee
    │   └── fileInput-test.coffee
    └── thsort
        ├── thsort-directive.coffee
        ├── thsort-screen.styl
        └── thsort-template.jade
```

This is the client (in browser, Angular) codebase for a medium sized project,
that manages a gradebook of student programming submissions. Notice that the
controllers, templates, and tests are all next to one another. Don't drive five
directories up and three over to get to a file for the same component. That's
just crazy.

Stassets understands this directory layout, but can be configured to any other
layout.

This is in line with [current best practices][ng-best] for AngularJS.

[ng-best]: https://docs.google.com/document/d/1XXMvReO8-Awi1EZXAXS4PzDzdNvV6pGcuaF4Q9821Es/pub

## Cascading File System

`stassets` has the concept of a Cascading File System. By creating a similar
directory structure in several root directories, `stassets` users can quickly
and easily implement a themeing or plugin system. To generate a cascading file
system, `stassets` joins a list of root directories with a set of file patterns.
Files in each root directory matching a pattern are joined, with files in higher
priority root directories overwriting those with lower priority.

## Configuration

***WIP*** These configuration options are used to extend and customize at
various places. Until 1.0, these may change subtly. They will not be stable
until 1.0.

### `root`

Required. String or Array<String>. Specifies the cascading search order for
watched files. Any file matching the same path in a later root directory will
override any files at that path in a prior directory. Especially useful for
creating themed systems.

```
./index.coffee:11:        @config.root = [@config.root] unless @config.root instanceof Array
```

### `livereload`

Optional. Boolean `false` or Object. Configure a livereload server. If not
present, uses [`tiny-lr`][tlr]'s default settings. If `false`, completely
disable Live Reload. Otherwise, is passed as-is to `tiny-lr`'s constructor.

```
./index.coffee:28:        unless @config.livereload is no
./index.coffee:29:            @livereload = new LR @config.livereload
```

[tlr]: https://www.npmjs.org/package/tiny-lr

### `scripts`

Configure application script settings.

#### `types`

Optional. Array<string> of script filename types. Files within the root folders
that have a name matching `*{type}.{ScriptTypes}` will be loaded, in order
defined in the array, to the `application.js` bundle. Type extensions are
determined based on registered filetype handlers in
`ScriptWatcher.renderers[handler]`. Default type list is `['main']`.

```
./Watchers/Script.coffee:16:        @config.scripts.types = @config.scripts.types || [
```

#### `compress`

Optional. Boolean to run bundled `application.js` through Uglify.

```
./Watchers/Script.coffee:63:        res @minify res if @config.scripts.compress
```

### `styles`

```
./Watchers/Style/Style.coffee:40:        if @config.vendors?.stylus?
./Watchers/Style/Style.coffee:41:            @config.vendors.stylus.map (_1)=>
./Watchers/Style/Style.coffee:42:                @config.vendors.prefix + '/' + _1
./Watchers/Style/Style.coffee:48:        .concat(@config.root.map (_1)-> "#{_1}/stylus/definitions/variables")
./Watchers/Style/Style.coffee:49:        .concat(@config.root.map (_1)-> "#{_1}/stylus/definitions/mixins")
```

### `templates`

Optional. Object configuring template rendering options.

### `baseModule`

Optional string. If present, will prefix all template module names with
`baseModule`.

```
./Watchers/Template.coffee:26:    if moduleRoot = @config.templates.baseModule
```

### `vendors`

#### `vendors.prefix`
```
./Watchers/Vendor/Vendor.coffee:15:        @config.vendors or=
./Watchers/Vendor/Vendor.coffee:18:        @config.vendors.prefix or= './'
./Watchers/Vendor/Vendor.coffee:19:        unless @config.vendors.prefix.length? and @config.vendors.prefix.map?
./Watchers/Vendor/Vendor.coffee:20:            @config.vendors.prefix = [@config.vendors.prefix]
./Watchers/Vendor/Vendor.coffee:22:        @config.root = @config.vendors.prefix
./Watchers/Vendor/Vendor.coffee:23:        @config.noRoot = true
./Watchers/Vendor/Vendor.coffee:30:        for root in @config.vendors.prefix
./Watchers/Vendor/Vendor.coffee:40:                    smResolvedPath = Path.join @config.vendors.prefix, smPath
```

#### `vendors.js`
#### `vendors.jsMaps`
```
./Watchers/Vendor/Script.coffee:7:        @config.vendors or= {}
./Watchers/Vendor/Script.coffee:8:        @config.vendors.js or= []
./Watchers/Vendor/Script.coffee:9:        @config.vendors.jsMaps or= []
./Watchers/Vendor/Script.coffee:12:    pattern: -> super @config.vendors.js
./Watchers/Vendor/Script.coffee:13:    getMaps: -> @config.vendors.jsMaps
```

#### `vendors.css`
#### `vendors.cssMaps`
```
./Watchers/Vendor/Style.coffee:7:        @config.vendors or= {}
./Watchers/Vendor/Style.coffee:8:        @config.vendors.css or= []
./Watchers/Vendor/Style.coffee:9:        @config.vendors.cssMaps or= []
./Watchers/Vendor/Style.coffee:12:    pattern: -> super @config.vendors.css
./Watchers/Vendor/Style.coffee:13:    getMaps: -> @config.vendors.cssMaps
```

## Changelog

* **0.3.5** *2014-11-17* Only emit one error, when a vendor file is unavailable.
* **0.3.4** *2014-11-10* Back on track with a sane build and changelog.
* **0.2.21** *2014-11-01* Assets accept module prefix in file name.
* **0.2.20** *2014-10-28* Handle errors in generated sourcemaps.
* **0.2.19** *2014-10-26* Generate SourceMaps for unsourcemapped vendors.
* **0.2.18** *2014-10-17* Jade rendering issue.
* **0.2.16, 17** *2014-10-17* Less CSS compiler and vanilla HTML compiler.
* **0.2.15** *2014-10-06* Better reporting syntax errors.
* **0.2.14** *2014-09-11* Documentation pass (13) & Bugfix (14).
* **0.2.12** *2014-09-07* [debug][https://www.npmjs.org/package/debug] for logs.
* **0.2.11** *2014-09-05* Bug fixes. See commit log.
* **0.2.7** *2014-08-20* Sourcemaps for Stylus files.
* **0.2.6** *2014-08-12* Many small bugfixes in .2 through .6.
* **0.2.1** *2014-07-21* Replaced Gaze with Sane.
* **0.2.0** *2014-07-19* Implements Cascading File System.
* **0.1.4** *2014-06-16* Includes Grunt task to save compiled assets to disk,
for pure static server (also great for tests). *This is likely to move to
grunt-stassets in the very near future!*
* **0.1** *2014-06-12* Understands the basic project structure. Works great for
rapid development.

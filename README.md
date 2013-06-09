Quick and easy way to build your product tours with Twitter Bootstrap Popovers.

## Demo and Documentation ##
[http://bootstraptour.com](http://bootstraptour.com)

## TODO ##
- Add the smooth scrolling when the popover is outside the viewport
- Define an appropriate tag + milestone system
- Integrate Travis build

## Contributing ##
Feel free to contribute with pull requests, bug reports or enhancement suggestions.

_We use [Grunt](http://gruntjs.com/) as our Task Runner, which makes your life way more easy ;)_


### How to run/develop

Install the dependencies

```bash
npm install -d
```

Files to be developed are located under `./src/` and `./test/spec/`
Compiled sources are then automatically put under `./build/` and `./test/build/`

Now you can perform a series of predefined Tasks by executing `grunt <task>:<target>`

```javascript
// clean all the 'build' directories, or specify a single target
clean
clean:default
clean:test

// compile the coffeescripts into the 'build' directories, or specify a single target
coffee
coffee:default
coffee:test
coffee:doc

// compile the less file into the 'build' directory with a minified version, or specify a single target
less
less:default
less:min

// minify the javascripts in the 'build' directory
uglify

// watch for changes of the coffeescripts (main and spec) and execute the assigned tasks, or specify a single target
watch
watch:default // tasks: clean:default, coffee:default, uglify
watch:test // tasks: clean:test, coffee:test, jasmine
watch:doc // tasks: coffee:doc (with livereload)

// run the jasmine specs headlessly through 'phantomjs'
jasmine

// copy sources into doc assets
copy

// small server to serve the static files
connect

// open automatically the browser to the port defined in connect options
open
```

There are also some _aliases_ for multiple tasks

```javascript
// alias for watch:default
grunt
grunt default

// alias for connect, open, watch:doc
grunt run

// alias for clean:default, coffee:default, coffee:doc, less, uglify, copy
grunt build

// alias for clean:test, coffee:test, jasmine
grunt test
```

### Live reload

Running `grunt run` will start a small server on port `3000` and opens the browser to the webpage. It will also start watching for changes in the `index.coffee` which will trigger then live reloading of the page in the browser.


## License ##
Code licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0).
Documentation licensed under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/).
Well, the same licenses as Bootstrap. We are lazy! ;)
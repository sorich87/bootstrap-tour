# Bootstrap Tour [![Build Status](https://travis-ci.org/sorich87/bootstrap-tour.png)](https://travis-ci.org/sorich87/bootstrap-tour)

Quick and easy way to build your product tours with Twitter Bootstrap Popovers.

## Demo and Documentation ##
[http://bootstraptour.com](http://bootstraptour.com)

## TODO ##
- Add the smooth scrolling when the popover is outside the viewport
- Define an appropriate tag + milestone system
- Integrate Travis build

## Contributing ##
Feel free to contribute with pull requests, bug reports or enhancement suggestions.

We use [Grunt](http://gruntjs.com/) and [Jasmine](http://pivotal.github.io/jasmine/). Both make your lives easier ;)

### How to run/develop

Install the dependencies

```bash
npm install -d
```

Files to be developed are located under `./src/` and `./test/spec/`.
Compiled sources are then automatically put under `./build/` and `./test/build/`

The following ones are the _aliases_ for multiple tasks. You can also run every task separately:

```javascript
// alias for watch:default
grunt
grunt default

// alias for connect, open, watch:doc
grunt run

// alias for clean:default, coffeelint, coffee:default, coffee:doc, less, uglify, copy
grunt build

// alias for clean:test, coffeelint:test, coffee:test, jasmine
grunt test
```

[More information here](http://bootstraptour.com/#grunt-usage)

## License ##
Code licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0).
Documentation licensed under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/).
Well, the same licenses as Bootstrap. We are lazy! ;)

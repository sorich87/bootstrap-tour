# Bootstrap Tour [![Build Status](https://travis-ci.org/sorich87/bootstrap-tour.png?branch=master)](https://travis-ci.org/sorich87/bootstrap-tour)

Quick and easy way to build your product tours with Twitter Bootstrap Popovers.

*Compatible with Bootstrap <= 3.0.0*

## Demo and Documentation ##
[http://bootstraptour.com](http://bootstraptour.com)

## TODO ##
- Add the smooth scrolling when the popover is outside the viewport
- Define an appropriate tag + milestone system

## Contributing ##
>In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

Feel free to contribute with pull requests, bug reports or enhancement suggestions.

We use [Grunt](http://gruntjs.com/) and [Jasmine](http://pivotal.github.io/jasmine/). Both make your lives easier ;)

### How to run/develop

Install the dependencies

```bash
npm install
```

Files to be developed are located under `./src/`
Compiled sources are then automatically put under `./build/` (and `./test/`)

Run main tasks (check `Gruntfile.coffee` for more infos)

```javascript
// Start a server and run the demo page
grunt
grunt run
// Compile all sources
grunt build
// Compile all sources and run the tests
grunt test
// Automatically release a new version (see below for more details)
grunt release
```

[More information here](http://bootstraptour.com/#grunt-usage)

## Releasing ##
Releasing a new version is completely automated using the Grunt task `grunt release`.

```javascript
grunt release // patch release
grunt release:minor // minor release
grunt release:major // major release
```

## License ##
Code licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0).
Documentation licensed under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/).
Well, the same licenses as Bootstrap. We are lazy! ;)

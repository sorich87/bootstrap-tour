# Bootstrap Tour [![Build Status](https://travis-ci.org/sorich87/bootstrap-tour.png?branch=master)](https://travis-ci.org/sorich87/bootstrap-tour)

Quick and easy way to build your product tours with Twitter Bootstrap Popovers.

*Compatible with Bootstrap >= 2.3.0*

## Demo and Documentation
[http://bootstraptour.com](http://bootstraptour.com)

## TODO
- Add the smooth scrolling when the popover is outside the viewport
- Define an appropriate tag + milestone system

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Grunt](http://gruntjs.com/).

Feel free to contribute with pull requests, bug reports or enhancement suggestions.

We use [Grunt](http://gruntjs.com/) and [Jasmine](http://pivotal.github.io/jasmine/). Both make your lives easier ;)

### How to build/develop

Files to be developed are located under `./src/`
Compiled sources are then automatically put under `./build/` (and `./test/`)

#### Installing the dependencies

```bash
npm install
gem install jekyll
```

#### Running Grunt tasks

```javascript
// Start a server and run the demo page
grunt
grunt run
// Compile all sources
grunt build
// Compile all sources and run the tests
grunt test
// Automatically release a new version
grunt release // patch release
grunt release:minor // minor release
grunt release:major // major release
```

Check `Gruntfile.coffee` for more infos.

## License

Code licensed under the [Apache License v2.0](http://www.apache.org/licenses/LICENSE-2.0).
Documentation licensed under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/).

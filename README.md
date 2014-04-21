# Bootstrap Tour
[![Build Status](http://img.shields.io/travis/sorich87/bootstrap-tour.svg)](https://travis-ci.org/sorich87/bootstrap-tour)
[![Dependency Status](https://david-dm.org/sorich87/bootstrap-tour.svg?theme=shields.io)](https://david-dm.org/sorich87/bootstrap-tour)
[![devDependency Status](https://david-dm.org/sorich87/bootstrap-tour/dev-status.svg?theme=shields.io)](https://david-dm.org/sorich87/bootstrap-tour#info=devDependencies)
[![NPM Version](http://img.shields.io/npm/v/bootstrap-tour.svg)](https://www.npmjs.org/)

Quick and easy way to build your product tours with Bootstrap Popovers.

*Compatible with Bootstrap >= 2.3.0*

## Demo and Documentation
[http://bootstraptour.com](http://bootstraptour.com)

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

Note for Mac OS X Mavericks (10.9) users: You will need to [jump through all these hoops](http://dean.io/setting-up-a-ruby-on-rails-development-environment-on-mavericks/) before you can install Jekyll.

#### Running Grunt tasks

```javascript
// Start a server and run the demo page
grunt
grunt go
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

# Bootstrap Tour
[![Build Status](http://img.shields.io/travis/sorich87/bootstrap-tour.svg?style=flat)](https://travis-ci.org/sorich87/bootstrap-tour)
[![Dependency Status](http://img.shields.io/david/sorich87/bootstrap-tour.svg?style=flat)](https://david-dm.org/sorich87/bootstrap-tour)
[![devDependency Status](http://img.shields.io/david/dev/sorich87/bootstrap-tour/dev-status.svg?style=flat)](https://david-dm.org/sorich87/bootstrap-tour#info=devDependencies)
[![NPM Version](http://img.shields.io/npm/v/bootstrap-tour.svg?style=flat)](https://www.npmjs.org/)

Quick and easy way to build your product tours with Bootstrap Popovers.

*Compatible with Bootstrap >= 2.3.0*

## Demo and Documentation
[http://bootstraptour.com](http://bootstraptour.com)

## Contributing
In lieu of a formal styleguide, take care to maintain the existing coding style. Add unit tests for any new or changed functionality. Lint and test your code using [Gulp](http://gulpjs.com/).

Feel free to contribute with pull requests, bug reports or enhancement suggestions.

We use [Gulp](http://gulpjs.com/) and [Jasmine](http://jasmine.github.io/). Both make your life easier ;)

### Develop

Files to be developed are located under `./src/`.
Compiled sources are then automatically put under `./build/`, `./test/` and `./docs/`.

#### Requirements

To begin, you need a few standard dependencies installed. These commands will install ruby, gem, node, npm, and grunt's command line runner:

##### Linux

```bash
$ sudo apt-get install ruby
$ sudo apt-get install ruby-dev
$ sudo apt-get install npm
$ sudo apt-get install nodejs-legacy
```

##### Mac OS X

```bash
ruby -e "$(curl -fsSL https://raw.github.com/mxcl/homebrew/go)"
\curl -L https://get.rvm.io | bash
rvm install ruby-2.1.1
brew install node
```

##### Development requirements

```bash
$ npm install -g gulp
$ npm install
$ gem install jekyll
```

For Mac OS X Mavericks (10.9) users: You will need to [jump through all these hoops](http://dean.io/setting-up-a-ruby-on-rails-development-environment-on-mavericks/) before you can install Jekyll.

#### Gulp usage

Run gulp and start to develop with ease:

```bash
$ gulp
$ gulp dist
$ gulp test
$ gulp docs
$ gulp clean
$ gulp server
$ gulp bump --type minor (major.minor.patch)
```

Check `gulpfile.coffee` to know more.

## License

Code licensed under the [MIT license](https://opensource.org/licenses/MIT).
Documentation licensed under [CC BY 3.0](http://creativecommons.org/licenses/by/3.0/).

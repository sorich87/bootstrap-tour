gulp = require 'gulp'
$ = require('gulp-load-plugins') lazy: false
extend = require('util')._extend
streamqueue = require 'streamqueue'
spawn = require('child_process').spawn
karma = require('karma').server
karmaConfig = require './karma.json'
pkg = require './package.json'
name = pkg.name

paths =
  src: './src'
  dist: './build'
  test: './test'
  docs: './docs'
server =
  host: 'localhost'
  port: 3000
banner = '''
  /* ========================================================================
   * <%= pkg.name %> - v<%= pkg.version %>
   * <%= pkg.homepage %>
   * ========================================================================
   * Copyright 2012-2013 <%= pkg.author.name %>
   *
   * ========================================================================
   * Licensed under the Apache License, Version 2.0 (the "License");
   * you may not use this file except in compliance with the License.
   * You may obtain a copy of the License at
   *
   *     http://www.apache.org/licenses/LICENSE-2.0
   *
   * Unless required by applicable law or agreed to in writing, software
   * distributed under the License is distributed on an "AS IS" BASIS,
   * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   * See the License for the specific language governing permissions and
   * limitations under the License.
   * ========================================================================
   */


  '''

# coffee
gulp.task 'coffee', ->
  gulp
  .src "#{paths.src}/coffee/#{name}.coffee"
  .pipe $.changed "#{paths.dist}/js"
  .pipe $.coffeelint './coffeelint.json'
  .pipe $.coffeelint.reporter()
    .on 'error', $.util.log
  .pipe $.coffee bare: true
    .on 'error', $.util.log
  .pipe $.header banner, pkg: pkg
  .pipe gulp.dest "#{paths.dist}/js"
  .pipe gulp.dest "#{paths.src}/docs/assets/js"
  .pipe gulp.dest "#{paths.test}"
  .pipe $.uglify()
  .pipe $.header banner, pkg: pkg
  .pipe $.rename suffix: '.min'
  .pipe gulp.dest "#{paths.dist}/js"

gulp.task 'coffee-standalone', ->
  streamqueue objectMode: true,
    gulp
    .src [
      "./node_modules/bootstrap/js/tooltip.js"
      "./node_modules/bootstrap/js/popover.js"
    ]
  ,
    gulp
    .src "#{paths.src}/coffee/#{name}.coffee"
    .pipe $.changed "#{paths.dist}/js"
    .pipe $.coffeelint './coffeelint.json'
    .pipe $.coffeelint.reporter()
      .on 'error', $.util.log
    .pipe $.coffee bare: true
      .on 'error', $.util.log
  .pipe $.concat "#{name}-standalone.js"
  .pipe $.header banner, pkg: pkg
  .pipe gulp.dest "#{paths.dist}/js"
  .pipe $.uglify()
  .pipe $.header banner, pkg: pkg
  .pipe $.rename suffix: '.min'
  .pipe gulp.dest "#{paths.dist}/js"

# less
gulp.task 'less', ->
  gulp
  .src [
    "#{paths.src}/less/#{name}.less"
  ]
  .pipe $.changed "#{paths.dist}/css"
  .pipe $.less()
    .on 'error', $.util.log
  .pipe $.header banner, pkg: pkg
  .pipe gulp.dest "#{paths.dist}/css"
  .pipe gulp.dest "#{paths.src}/docs/assets/css"
  .pipe $.less compress: true, cleancss: true
  .pipe $.header banner, pkg: pkg
  .pipe $.rename suffix: '.min'
  .pipe gulp.dest "#{paths.dist}/css"

gulp.task 'less-standalone', ->
  gulp
  .src "#{paths.src}/less/#{name}-standalone.less"
  .pipe $.changed "#{paths.dist}/css"
  .pipe $.less()
    .on 'error', $.util.log
  .pipe $.header banner, pkg: pkg
  .pipe gulp.dest "#{paths.dist}/css"
  .pipe $.less compress: true, cleancss: true
  .pipe $.header banner, pkg: pkg
  .pipe $.rename suffix: '.min'
  .pipe gulp.dest "#{paths.dist}/css"

# test
gulp.task 'test-coffee', ['coffee'], ->
  gulp
  .src "#{paths.src}/coffee/#{name}.spec.coffee"
  .pipe $.changed paths.test
  .pipe $.coffeelint.reporter()
    .on 'error', $.util.log
  .pipe $.coffee()
    .on 'error', $.util.log
  .pipe gulp.dest paths.test

gulp.task 'test-go', ['coffee-test'], (done) ->
  karma.start extend(karmaConfig, singleRun: true), done

# docs
gulp.task 'docs-build', ['coffee', 'less'], (done) ->
  spawn 'jekyll', ['build']
    .on 'close', done

gulp.task 'docs-coffee', ['docs-build'], ->
  gulp
  .src "#{paths.src}/coffee/#{name}.docs.coffee"
  .pipe $.changed "#{paths.docs}/assets/js"
  .pipe $.coffeelint.reporter()
    .on 'error', $.util.log
  .pipe $.coffee()
    .on 'error', $.util.log
  .pipe gulp.dest "#{paths.docs}/assets/js"

# clean
gulp.task 'clean-dist', ->
  gulp
  .src paths.dist
  .pipe $.clean()

gulp.task 'clean-test', ->
  gulp
  .src paths.test
  .pipe $.clean()

gulp.task 'clean-docs', ->
  gulp
  .src paths.docs
  .pipe $.clean()

# connect
gulp.task 'connect', ['docs'], ->
  $.connect.server
    root: [paths.docs]
    host: server.host
    port: server.port
    livereload: true

# open
gulp.task 'open', ['connect'], ->
  gulp
  .src "#{paths.docs}/index.html"
  .pipe $.open '', url: "http://#{server.host}:#{server.port}"

gulp.task 'watch', ['connect'], ->
  gulp.watch "#{paths.src}/coffee/#{name}.coffee", ['coffee', 'coffee-standalone']
  gulp.watch "#{paths.src}/less/#{name}.less", ["less"]
  gulp.watch [
    "#{paths.src}/less/#{name}-standalone.less"
    "#{paths.src}/less/standalone/**/*.less"
  ], ['less-standalone']
  gulp.watch "#{paths.src}/coffee/#{name}.spec.coffee", ['test']
  gulp.watch [
    "#{paths.src}/coffee/#{name}.docs.coffee"
    "#{paths.src}/docs/**/*"
  ], ['docs']
  gulp.watch [
    "#{paths.dist}/js/**/*.js"
    "#{paths.dist}/css/**/*.css"
    "#{paths.docs}/index.html"
  ]
  .on 'change', (event) ->
    gulp.src event.path
    .pipe $.connect.reload()

# tasks
gulp.task 'clean', ['clean-dist', 'clean-test', 'clean-docs']
gulp.task 'server', ['connect', 'open', 'watch']
gulp.task 'dist', ['coffee', 'coffee-standalone', 'less', 'less-standalone']
gulp.task 'test', ['coffee', 'test-coffee', 'test-go']
gulp.task 'docs', ['coffee', 'less', 'docs-build', 'docs-coffee']
gulp.task 'default', ['dist', 'docs', 'server']

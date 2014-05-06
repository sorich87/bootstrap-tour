gulp = require 'gulp'
plugins = require('gulp-load-plugins')()
streamqueue = require 'streamqueue'
spawn = require('child_process').spawn
pkg = require './package.json'
name = pkg.name

SOURCE_PATH = './src'
DIST_PATH = './build'
TEST_PATH = './test'
DOCS_PATH = './docs'
SERVER_HOST = 'localhost'
SERVER_PORT = 3000
BANNER = """
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


  """

gulp.task 'coffee', ->
  gulp
  .src "#{SOURCE_PATH}/coffee/#{name}.coffee"
  .pipe plugins.changed "#{DIST_PATH}/js"
  .pipe plugins.coffeelint './coffeelint.json'
  .pipe plugins.coffeelint.reporter()
    .on 'error', plugins.util.log
  .pipe plugins.coffee bare: true
    .on 'error', plugins.util.log
  .pipe plugins.header BANNER, pkg: pkg
  .pipe gulp.dest "#{DIST_PATH}/js"
  .pipe gulp.dest "#{SOURCE_PATH}/docs/assets/js"
  .pipe plugins.uglify()
  .pipe plugins.header BANNER, pkg: pkg
  .pipe plugins.rename suffix: '.min'
  .pipe gulp.dest "#{DIST_PATH}/js"

gulp.task 'coffee-standalone', ->
  streamqueue objectMode: true,
    gulp
    .src [
      "#{SOURCE_PATH}/js/standalone/tooltip.js"
      "#{SOURCE_PATH}/js/standalone/popover.js"
    ]
  ,
    gulp
    .src "#{SOURCE_PATH}/coffee/#{name}.coffee"
    .pipe plugins.changed "#{DIST_PATH}/js"
    .pipe plugins.coffeelint './coffeelint.json'
    .pipe plugins.coffeelint.reporter()
      .on 'error', plugins.util.log
    .pipe plugins.coffee bare: true
      .on 'error', plugins.util.log
  .pipe plugins.concat "#{name}-standalone.js"
  .pipe plugins.header BANNER, pkg: pkg
  .pipe gulp.dest "#{DIST_PATH}/js"
  .pipe plugins.uglify()
  .pipe plugins.header BANNER, pkg: pkg
  .pipe plugins.rename suffix: '.min'
  .pipe gulp.dest "#{DIST_PATH}/js"

gulp.task 'coffee-test', ['coffee'], ->
  gulp
  .src "#{SOURCE_PATH}/coffee/#{name}.spec.coffee"
  .pipe plugins.changed "#{TEST_PATH}"
  .pipe plugins.coffeelint.reporter()
    .on 'error', plugins.util.log
  .pipe plugins.coffee()
    .on 'error', plugins.util.log
  .pipe gulp.dest "#{TEST_PATH}"

gulp.task 'less', ->
  gulp
  .src "#{SOURCE_PATH}/less/#{name}.less"
  .pipe plugins.changed "#{DIST_PATH}/css"
  .pipe plugins.less()
    .on 'error', plugins.util.log
  .pipe plugins.header BANNER, pkg: pkg
  .pipe gulp.dest "#{DIST_PATH}/css"
  .pipe plugins.less compress: true, cleancss: true
  .pipe plugins.header BANNER, pkg: pkg
  .pipe plugins.rename suffix: '.min'
  .pipe gulp.dest "#{DIST_PATH}/css"

gulp.task 'less-standalone', ->
  gulp
  .src "#{SOURCE_PATH}/less/#{name}-standalone.less"
  .pipe plugins.changed "#{DIST_PATH}/css"
  .pipe plugins.less()
    .on 'error', plugins.util.log
  .pipe plugins.header BANNER, pkg: pkg
  .pipe gulp.dest "#{DIST_PATH}/css"
  .pipe plugins.less compress: true, cleancss: true
  .pipe plugins.header BANNER, pkg: pkg
  .pipe plugins.rename suffix: '.min'
  .pipe gulp.dest "#{DIST_PATH}/css"

gulp.task 'karma', ['coffee-test'], ->
  gulp
  .src "#{TEST_PATH}/#{name}.spec.js"
  .pipe plugins.karma()
    .on 'error', (error) -> throw error

gulp.task 'jekyll', (done) ->
  spawn 'jekyll', ['build']
  .on 'close', done

gulp.task 'docs', ['jekyll'], ->
  gulp
  .src './CNAME'
  .pipe gulp.dest DOCS_PATH

gulp.task 'clean-dist', ->
  gulp
  .src DIST_PATH
  .pipe plugins.clean()

# gulp.task 'clean-test', ->
#   gulp
#   .src TEST_PATH
#   .pipe plugins.clean()

gulp.task 'clean-docs', ->
  gulp
  .src DOCS_PATH
  .pipe plugins.clean()

gulp.task 'connect', ['docs'], ->
  plugins.connect.server
    root: [DOCS_PATH]
    host: SERVER_HOST
    port: SERVER_PORT
    livereload: true

gulp.task 'open', ['connect'], ->
  gulp
  .src "#{DOCS_PATH}/index.html"
  .pipe plugins.open '', url: "http://#{SERVER_HOST}:#{SERVER_PORT}"

gulp.task 'watch', ['connect'], ->
  gulp.watch "#{SOURCE_PATH}/coffee/#{name}.coffee", ['coffee']
  gulp.watch "#{SOURCE_PATH}/less/#{name}.less", ['less']
  gulp.watch [
    "#{SOURCE_PATH}/less/#{name}-standalone.less"
    "#{SOURCE_PATH}/less/standalone/**/*.less"
  ], ['less-standalone']
  gulp.watch "#{SOURCE_PATH}/coffee/#{name}.spec.coffee", ['test']
  gulp.watch "#{SOURCE_PATH}/docs/**/*", ['docs']
  gulp.watch [
    "#{DIST_PATH}/js/**/*.js"
    "#{DIST_PATH}/css/**/*.css"
    "#{DOCS_PATH}/index.html"
  ]
  .on 'change', (event) ->
    gulp.src event.path
    .pipe plugins.connect.reload()

gulp.task 'clean', ['clean-dist', 'clean-test', 'clean-docs']
gulp.task 'server', ['connect', 'open', 'watch']
gulp.task 'dist', ['coffee', 'coffee-standalone', 'less', 'less-standalone']
gulp.task 'test', ['coffee', 'coffee-test', 'karma']
gulp.task 'default', ['dist', 'docs', 'server']

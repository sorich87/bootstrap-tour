const KarmaServer = require('karma').Server;
const gulp = require('gulp');
const $ = require('gulp-load-plugins')({lazy: false});
const extend = require('util')._extend;
const streamqueue = require('streamqueue');
const { spawn } = require('child_process');
const pkg = require('./package.json');
const { name } = pkg;

const paths = {
  src: './src',
  dist: './build',
  test: './test',
  docs: './docs'
};
const server = {
  host: 'localhost',
  port: 3000
};
const banner = `\
/* ========================================================================
 * <%= pkg.name %> - v<%= pkg.version %>
 * <%= pkg.homepage %>
 * ========================================================================
 * Copyright 2012-2017 <%= pkg.author.name %>
 *
 * ========================================================================
 * Licensed under the MIT License (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://opensource.org/licenses/MIT
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================================
 */

\
`;

// coffee
gulp.task('coffee', () =>
  gulp
  .src(`${paths.src}/coffee/${name}.coffee`)
  .pipe($.changed(`${paths.dist}/js`))
  .pipe($.coffeelint('./coffeelint.json'))
  .pipe($.coffeelint.reporter())
    .on('error', $.util.log)
  .pipe($.coffee({bare: true}))
    .on('error', $.util.log)
  .pipe($.header(banner, {pkg}))
  .pipe(gulp.dest(`${paths.dist}/js`))
  .pipe(gulp.dest(`${paths.src}/docs/assets/js`))
  .pipe(gulp.dest(paths.test))
  .pipe($.uglify())
  .pipe($.header(banner, {pkg}))
  .pipe($.rename({suffix: '.min'}))
  .pipe(gulp.dest(`${paths.dist}/js`))
);

gulp.task('coffee-standalone', () =>
  streamqueue({objectMode: true},
    gulp
    .src([
      './node_modules/popper.js/dist/umd/popper.js',
      './node_modules/bootstrap/js/dist/util.js',
      './node_modules/bootstrap/js/dist/tooltip.js',
      './node_modules/bootstrap/js/dist/popover.js'
    ])
  ,
    gulp
    .src(`${paths.src}/coffee/${name}.coffee`)
    .pipe($.changed(`${paths.dist}/js`))
    .pipe($.coffeelint('./coffeelint.json'))
    .pipe($.coffeelint.reporter())
      .on('error', $.util.log)
    .pipe($.coffee({bare: true}))
      .on('error', $.util.log)).pipe($.concat(`${name}-standalone.js`))
  .pipe($.header(banner, {pkg}))
  .pipe(gulp.dest(`${paths.dist}/js`))
  .pipe(gulp.dest(paths.test))
  .pipe($.uglify())
  .pipe($.header(banner, {pkg}))
  .pipe($.rename({suffix: '.min'}))
  .pipe(gulp.dest(`${paths.dist}/js`))
);

// scss
gulp.task('scss', () =>
  gulp
  .src([
    `${paths.src}/scss/${name}.scss`
  ])
  .pipe($.changed(`${paths.dist}/css`))
  .pipe($.sass().on('error', $.sass.logError))
  .pipe($.header(banner, {pkg}))
  .pipe(gulp.dest(`${paths.dist}/css`))
  .pipe(gulp.dest(`${paths.src}/docs/assets/css`))
  .pipe($.sass({outputStyle: 'compressed'}))
  .pipe($.header(banner, {pkg}))
  .pipe($.rename({suffix: '.min'}))
  .pipe(gulp.dest(`${paths.dist}/css`))
);

gulp.task('scss-standalone', () =>
  gulp
  .src(`${paths.src}/scss/${name}-standalone.scss`)
  .pipe($.changed(`${paths.dist}/css`))
  .pipe($.sass({ includePaths: ['./node_modules/bootstrap/scss/'] }).on('error', $.sass.logError))
  .pipe($.header(banner, {pkg}))
  .pipe(gulp.dest(`${paths.dist}/css`))
  .pipe($.sass({ outputStyle: 'compressed' })).pipe($.header(banner, {pkg}))
  .pipe($.rename({suffix: '.min'}))
  .pipe(gulp.dest(`${paths.dist}/css`))
);

// test
gulp.task('test-coffee', ['coffee'], () =>
  gulp
  .src(`${paths.src}/coffee/${name}.spec.coffee`)
  .pipe($.changed(paths.test))
  .pipe($.coffeelint('./coffeelint.json'))
  .pipe($.coffeelint.reporter())
    .on('error', $.util.log)
  .pipe($.coffee())
    .on('error', $.util.log)
  .pipe(gulp.dest(paths.test))
);

gulp.task('test-go', ['test-coffee'], done => new KarmaServer({ configFile: __dirname + '/karma.conf.js', singleRun: true}, done).start());

// docs
gulp.task('docs-build', ['coffee', 'scss'], done =>
  spawn((process.platform === 'win32' ? 'jekyll.bat' : 'jekyll'), ['build'])
    .on('close', done)
);

gulp.task('docs-copy', ['docs-build'], () =>
  gulp
    .src([
      './node_modules/blueimp-md5/js/md5.min.js',
      './node_modules/blueimp-md5/js/md5.min.js.map',
      './node_modules/bootstrap/dist/css/bootstrap.min.css',
      './node_modules/bootstrap/dist/css/bootstrap.min.css.map',
      './node_modules/bootstrap/dist/js/bootstrap.min.js',
      './node_modules/jquery/dist/jquery.min.js',
      './node_modules/popper.js/dist/umd/popper.min.js',
      './node_modules/popper.js/dist/umd/popper.min.js.map'
    ])
    .pipe(gulp.dest(`${paths.docs}/components`))
);

gulp.task('docs-coffee', ['docs-build'], () =>
  gulp
  .src(`${paths.src}/coffee/${name}.docs.coffee`)
  .pipe($.changed(`${paths.docs}/assets/js`))
  .pipe($.coffeelint.reporter())
    .on('error', $.util.log)
  .pipe($.coffee())
    .on('error', $.util.log)
  .pipe(gulp.dest(`${paths.docs}/assets/js`))
);

// clean
gulp.task('clean-dist', () =>
  gulp
  .src(paths.dist)
  .pipe($.clean())
);

gulp.task('clean-test', () =>
  gulp
  .src(paths.test)
  .pipe($.clean())
);

gulp.task('clean-docs', () =>
  gulp
  .src(paths.docs)
  .pipe($.clean())
);

// connect
gulp.task('connect', ['docs'], () =>
  $.connect.server({
    root: [paths.docs],
    host: server.host,
    port: server.port,
    livereload: true
  })
);

// open
gulp.task('open', ['connect'], () =>
  gulp
  .src(`${paths.docs}/index.html`)
  .pipe($.open({uri: `http://${server.host}:${server.port}`}))
);

gulp.task('watch', ['connect'], function() {
  gulp.watch(`${paths.src}/coffee/${name}.coffee`, ['coffee', 'coffee-standalone']);
  gulp.watch(`${paths.src}/scss/${name}.scss`, ["scss", "scss-standalone"]);
  gulp.watch(`${paths.src}/scss/${name}-standalone.scss`, ['scss-standalone']);
  gulp.watch(`${paths.src}/coffee/${name}.spec.coffee`, ['test']);
  gulp.watch([
    `${paths.src}/coffee/${name}.docs.coffee`,
    `${paths.src}/docs/**/*`
  ], ['docs']);
  gulp.watch([
    `${paths.dist}/js/**/*.js`,
    `${paths.dist}/css/**/*.css`,
    `${paths.docs}/index.html`
  ])
  .on('change', event =>
    gulp.src(event.path)
    .pipe($.connect.reload())
  );
});

// bump
gulp.task('bump', ['test'], function() {
  const bumpType = $.util.env.type || 'patch';

  gulp.src(['./package.json', './smart.json'])
    .pipe($.bump({type: bumpType}))
    .pipe(gulp.dest('./'));
});

// tasks
gulp.task('clean', ['clean-dist', 'clean-test', 'clean-docs']);
gulp.task('server', ['connect', 'open', 'watch']);
gulp.task('dist', ['coffee', 'coffee-standalone', 'scss', 'scss-standalone']);
gulp.task('test', ['coffee', 'test-coffee', 'test-go']);
gulp.task('docs', ['coffee', 'scss', 'docs-build', 'docs-copy', 'docs-coffee']);
gulp.task('default', ['dist', 'docs', 'server']);

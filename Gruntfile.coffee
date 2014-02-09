"use strict"

module.exports = (grunt) ->

  # load all grunt tasks
  require("matchdep").filterDev("grunt-*").forEach grunt.loadNpmTasks

  grunt.initConfig

    pkg: grunt.file.readJSON 'package.json'

    meta:
      banner: "/* ===========================================================\n" +
        "# <%= pkg.name %> - v<%= pkg.version %>\n" +
        "# <%= pkg.homepage %>\n" +
        "# ==============================================================\n" +
        "# Copyright 2012-2013 <%= pkg.author.name %>\n" +
        "#\n" +
        "# Licensed under the Apache License, Version 2.0 (the \"License\");\n" +
        "# you may not use this file except in compliance with the License.\n" +
        "# You may obtain a copy of the License at\n" +
        "#\n" +
        "#     http://www.apache.org/licenses/LICENSE-2.0\n" +
        "#\n" +
        "# Unless required by applicable law or agreed to in writing, software\n" +
        "# distributed under the License is distributed on an \"AS IS\" BASIS,\n" +
        "# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n" +
        "# See the License for the specific language governing permissions and\n" +
        "# limitations under the License.\n" +
        "*/\n"

    coffeelint:
      options:
        indentation:
          value: 2
          level: "error"
        no_trailing_semicolons:
          level: "error"
        no_trailing_whitespace:
          level: "error"
        max_line_length:
          level: "ignore"
      default: ["Gruntfile.coffee", "src/{,*/}*.coffee"]
      doc: ["Gruntfile.coffee", "docs/assets/coffee/*.coffee"]

    clean:
      default: "build"
      docs: "docs-build"
      test: "test/spec"

    coffee:
      options:
        bare: true
      default:
        expand: true
        flatten: true
        cwd: "src/coffee"
        src: ["*.coffee"]
        dest: "build/js"
        ext: ".js"
      test:
        expand: true
        flatten: true
        cwd: "src/spec"
        src: ["*.spec.coffee"]
        dest: "test/spec"
        ext: ".spec.js"
      doc:
        src: "docs/assets/coffee/docs.coffee"
        dest: "docs/assets/js/docs.js"

    concat:
      options:
        banner: "<%= meta.banner %>"
      standalone:
        options:
          banner: ""
        src: [
          "src/js/standalone/tooltip.js",
          "src/js/standalone/popover.js",
          "build/js/<%= pkg.name %>.js"
        ]
        dest: "build/js/<%= pkg.name %>-standalone.js"
      script:
        expand: true
        flatten: true
        cwd: "build/js"
        src: ["*.js"]
        dest: "build/js"
        ext: ".js"
      style:
        expand: true
        flatten: true
        cwd: "build/css"
        src: ["*.css", "!*.min.css"]
        dest: "build/css"
        ext: ".css"
      style_min:
        expand: true
        flatten: true
        cwd: "build/css"
        src: ["*.min.css"]
        dest: "build/css"
        ext: ".min.css"

    less:
      default:
        files:
          "build/css/<%= pkg.name %>.css": "src/less/<%= pkg.name %>.less"
          "build/css/<%= pkg.name %>-standalone.css": [
            "src/less/standalone/bootstrap.less",
            "src/less/<%= pkg.name %>.less"
          ]
      min:
        options:
          compress: true
          cleancss: true
        files:
          "build/css/<%= pkg.name %>.min.css": "src/less/<%= pkg.name %>.less"
          "build/css/<%= pkg.name %>-standalone.min.css": [
            "src/less/standalone/bootstrap.less",
            "src/less/<%= pkg.name %>.less"
          ]

    uglify:
      options:
        banner: "<%= meta.banner %>"
      default:
        expand: true
        flatten: true
        cwd: "build/js"
        src: ["*.js"]
        dest: "build/js"
        ext: ".min.js"

    jekyll:
      build: {}

    watch:
      options:
        livereload: true
      default:
        files: ["src/coffee/*.coffee"]
        tasks: ["build"]
      test:
        files: ["src/spec/*.coffee"]
        tasks: ["test"]
      doc:
        files: ["docs/assets/coffee/*.coffee"]
        tasks: ["coffeelint:doc", "coffee:doc"]
      jekyll:
        files: [
          "docs/{,*/}*.html",
          "docs/assets/{,*/}*"
        ]
        tasks: ["jekyll"]

    jasmine:
      options:
        keepRunner: true
        vendor: [
          "docs/assets/vendor/jquery.js"
          "docs/assets/vendor/bootstrap.js"
        ]
        specs: "test/spec/*.spec.js"
      src: "build/js/<%= pkg.name %>.js"

    copy:
      default:
        files: [
          "docs/assets/js/bootstrap-tour.js": "build/js/bootstrap-tour.js"
          "docs/assets/css/bootstrap-tour.css": "build/css/bootstrap-tour.css"
        ]
      docs:
        src: "CNAME"
        dest: "docs-build/CNAME"

    connect:
      default:
        options:
          livereload: true
          port: 3000
          base: "docs-build"

    open:
      default:
        path: "http://localhost:<%= connect.default.options.port %>"

    bump:
      options:
        files: ["package.json", "bower.json"]
        updateConfigs: ["pkg"]
        commit: true
        commitMessage: "Bump version to %VERSION%"
        commitFiles: ["-a"]
        createTag: true
        tagName: "v%VERSION%"
        tagMessage: "Version %VERSION%"
        push: true
        pushTo: "origin"
        gitDescribeOptions: "--tags --always --abbrev=1 --dirty=-d"

    replace:
      options:
        patterns: [
          {
            match: "/Version \\d+\\.\\d+\\.\\d+/g"
            replacement: "Version <%= pkg.version %>"
            expression: true
          }
        ]
      default:
        files: [
          {
            expand: true
            flatten: true
            src: ["docs/index.html"]
            dest: "docs/"
          }
        ]

  grunt.registerTask "default", ["go"]
  grunt.registerTask "go", ["build", "connect", "open", "watch"]
  grunt.registerTask "build-code", ["clean", "coffeelint", "coffee", "less", "concat", "uglify", "copy:default"]
  grunt.registerTask "build-docs", ["jekyll", "copy:docs"]
  grunt.registerTask "build", ["build-code", "build-docs"]
  grunt.registerTask "test", ["build-code", "jasmine"]
  grunt.registerTask "release", "Release a new version, push it and publish it", (target) ->
    target = "patch" unless target
    grunt.task.run "bump-only:#{target}", "test", "replace", "bump-commit"

'use strict'

module.exports = (grunt)->
  # project configuration
  grunt.initConfig
    # load package information
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
      default: ["Gruntfile.coffee", "src/**/*.coffee"]
      doc: ["Gruntfile.coffee", "docs/*.coffee"]

    clean:
      default: "build"
      test: "test"

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
        dest: "test"
        ext: ".spec.js"
      doc:
        src: "docs/index.coffee"
        dest: "docs/assets/js/index.js"

    concat:
      options:
        banner: "<%= meta.banner %>"
      default:
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
        src: "src/less/<%= pkg.name %>.less"
        dest: "build/css/<%= pkg.name %>.css"
      min:
        options:
          compress: true
          cleancss: true
        src: "src/less/<%= pkg.name %>.less"
        dest: "build/css/<%= pkg.name %>.min.css"

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

    watch:
      default:
        files: ["src/coffee/*.coffee"]
        tasks: ["build"]
      test:
        files: ["src/spec/*.coffee"]
        tasks: ["test"]
      doc:
        files: ["docs/*.coffee"]
        tasks: ["coffeelint:doc", "coffee:doc"]
        options:
          livereload: true

    jasmine:
      options:
        keepRunner: true
        vendor: [
          "docs/assets/vendor/jquery.js"
          "docs/assets/vendor/bootstrap.js"
        ]
        specs: "test/*.spec.js"
      src: "build/js/<%= pkg.name %>.js"

    copy:
      default:
        files: [
            expand: true
            cwd: "build/js"
            dest: "docs/assets/js"
            src: ["*.js"]
          ,
            expand: true
            cwd: "build/css"
            dest: "docs/assets/css"
            src: ["*.css"]
        ]

    connect:
      default:
        options:
          port: 3000
          base: "docs"

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

  # load plugins that provide the tasks defined in the config
  grunt.loadNpmTasks "grunt-bump"
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-jasmine"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-notify"
  grunt.loadNpmTasks "grunt-open"
  grunt.loadNpmTasks "grunt-replace"

  # register tasks
  grunt.registerTask "default", ["run"]
  grunt.registerTask "run", ["build", "connect", "open", "watch:doc"]
  grunt.registerTask "build", ["clean", "coffeelint", "coffee", "less", "concat", "uglify", "copy"]
  grunt.registerTask "test", ["build", "jasmine"]
  grunt.registerTask "release", "Release a new version, push it and publish it", (target)->
    target = "patch" unless target
    grunt.task.run "bump-only:#{target}", "test", "replace", "bump-commit"

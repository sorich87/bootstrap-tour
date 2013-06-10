module.exports = (grunt)->
  # project configuration
  grunt.initConfig
    # load package information
    pkg: grunt.file.readJSON 'package.json'

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
      test: ["Gruntfile.coffee", "test/**/*.coffee"]
      doc: ["Gruntfile.coffee", "docs/*.coffee"]

    clean:
      default: "build"
      test: "test/build"

    coffee:
      default:
        src: "src/coffee/bootstrap-tour.coffee"
        dest: "build/js/bootstrap-tour.js"
      test:
        src: "test/spec/bootstrap-tour.spec.coffee"
        dest: "test/build/bootstrap-tour.spec.js"
      doc:
        src: "docs/index.coffee"
        dest: "docs/assets/js/index.js"

    less:
      default:
        src: "src/less/bootstrap-tour.less"
        dest: "build/css/bootstrap-tour.css"
      min:
        src: "src/less/bootstrap-tour.less"
        dest: "build/css/bootstrap-tour.min.css"
        options:
          yuicompress: true

    uglify:
      default:
        src: "build/js/bootstrap-tour.js"
        dest: "build/js/bootstrap-tour.min.js"

    # watching for changes
    watch:
      default:
        files: ["src/coffee/*.coffee"]
        tasks: ["clean:default", "coffeelint:default", "coffee:default", "uglify"]
      test:
        files: ["test/spec/*.coffee"]
        tasks: ["clean:test", "coffeelint:test", "coffee:test", "jasmine"]
      doc:
        files: ["docs/*.coffee"]
        tasks: ["coffeelint:doc", "coffee:doc"]
        options:
          livereload: true

    jasmine:
      # keep an eye on the order of deps import
      src: [
        "docs/assets/vendor/jquery.js"
        "docs/assets/vendor/jquery.cookie.js"
        "docs/assets/vendor/bootstrap-alert.js"
        "docs/assets/vendor/bootstrap-tooltip.js"
        "docs/assets/vendor/bootstrap-popover.js"
        "build/js/bootstrap-tour.js"
      ]
      options:
        specs: "test/build/bootstrap-tour.spec.js"

    copy:
      default:
        files: [
            expand: true,
            cwd: "build/js",
            dest: "docs/assets/js",
            src: ["*.js"]
          ,
            expand: true,
            cwd: "build/css",
            dest: "docs/assets/css",
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

    # TODO:
    # - browser sample page reloads on watch when developing

  # load plugins that provide the tasks defined in the config
  grunt.loadNpmTasks "grunt-coffeelint"
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-jasmine"
  grunt.loadNpmTasks "grunt-contrib-copy"
  grunt.loadNpmTasks "grunt-contrib-connect"
  grunt.loadNpmTasks "grunt-open"

  # register tasks
  grunt.registerTask "run", ["connect", "open", "watch:doc"]
  grunt.registerTask "build", ["clean:default", "coffeelint", "coffee:default", "coffee:doc", "less", "uglify", "copy"]
  grunt.registerTask "test", ["clean:test", "coffeelint:test", "coffee:test", "jasmine"]
  grunt.registerTask "default", ["watch:default"]
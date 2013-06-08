module.exports = (grunt)->
  # project configuration
  grunt.initConfig
    # load package information
    pkg: grunt.file.readJSON 'package.json'

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
        tasks: ["clean:default", "coffee:default", "uglify"]
      test:
        files: ["test/spec/*.coffee"]
        tasks: ["clean:test", "coffee:test", "jasmine"]

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

    # TODO:
    # - browser sample page reloads on watch when developing

  # load plugins that provide the tasks defined in the config
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-jasmine"
  grunt.loadNpmTasks "grunt-contrib-copy"

  # register tasks
  grunt.registerTask "build", ["clean:default", "coffee:default", "coffee:doc", "less", "uglify", "copy"]
  grunt.registerTask "test", ["clean:test", "coffee:test", "jasmine"]
  grunt.registerTask "default", ["watch:default"]
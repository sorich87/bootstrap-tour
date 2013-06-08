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
        "deps/jquery.js"
        "deps/jquery.cookie.js"
        "deps/bootstrap-alert.js"
        "deps/bootstrap-tooltip.js"
        "deps/bootstrap-popover.js"
        "build/js/*.js"
      ]
      options:
        specs: "test/build/bootstrap-tour.spec.js"

    # TODO:
    # - download bootstrap.js / bootstrap.css from cdn if not present
    # - jasmine html runner
    # - browser sample page reloads on watch when developing

  # load plugins that provide the tasks defined in the config
  grunt.loadNpmTasks "grunt-contrib-clean"
  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-less"
  grunt.loadNpmTasks "grunt-contrib-uglify"
  grunt.loadNpmTasks "grunt-contrib-watch"
  grunt.loadNpmTasks "grunt-contrib-jasmine"

  # register tasks
  grunt.registerTask "build", ["clean:default", "coffee:default", "less", "uglify"]
  grunt.registerTask "test", ["clean:test", "coffee:test", "jasmine"]
  grunt.registerTask "default", ["coffee", "watch"]
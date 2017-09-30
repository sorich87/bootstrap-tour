module.exports = function(config) {
  config.set({
    browsers: ['ChromeHeadless', 'Firefox'],
    files: [
      'bower_components/jquery/dist/jquery.js',
      'bower_components/bootstrap/dist/js/bootstrap.js',
      'test/bootstrap-tour.js',
      'test/bootstrap-tour.spec.js'
    ],
    frameworks: ['jasmine']
  });
};

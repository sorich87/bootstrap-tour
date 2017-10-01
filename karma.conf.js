module.exports = function(config) {
  config.set({
    browsers: ['ChromeHeadless', 'Firefox'],
    files: [
      'node_modules/jquery/dist/jquery.js',
      'test/bootstrap-tour-standalone.js',
      'test/bootstrap-tour.spec.js'
    ],
    frameworks: ['jasmine']
  });
};

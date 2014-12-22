/* ========================================================================
 * bootstrap-tour - v0.9.3
 * http://bootstraptour.com
 * ========================================================================
 * Copyright 2012-2013 Ulrich Sossou
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

(function($, window) {
  'use strict';
  var Tour, TourStep;
  Tour = (function() {
    function Tour(options) {
      if (options == null) {
        options = {};
      }
      this.options = $.extend({}, Tour.defaults, options);
      this.steps = [];
      this.force = false;
      this.inited = false;
      this.$backdrop = null;
      this.$backdropOverlay = null;
      if (this.options.steps.length) {
        this.addSteps(this.options.steps);
      }
      this;
    }

    Tour.prototype.addSteps = function(steps) {
      var step, _i, _len;
      for (_i = 0, _len = steps.length; _i < _len; _i++) {
        step = steps[_i];
        this.addStep(step);
      }
      return this;
    };

    Tour.prototype.addStep = function(step) {
      this.steps.push(new TourStep(step));
      return this;
    };

    Tour.prototype.step = function(i) {
      return this.steps[i];
    };

    Tour.prototype.currentStep = function(value) {
      if (typeof value === 'undefined') {
        return this.current;
      }
      this.current = value;
      return this._setState('current_step', value);
    };

    Tour.prototype.init = function(force) {
      var current;
      this.force = force;
      current = this._getState('current_step');
      this.current = current === null ? current : parseInt(current, 10);
      if (this.ended()) {
        this._debug('Tour ended, init prevented.');
        return this;
      }
      this._keyboard(this.options.keyboard);
      this._mouse();
      this._onResize((function(_this) {
        return function() {
          return _this.showStep(_this.current);
        };
      })(this));
      if (this.current != null) {
        this.showStep(this.current);
      }
      this.inited = true;
      return this;
    };

    Tour.prototype.start = function(force) {
      if (force == null) {
        force = false;
      }
      if (!this.inited) {
        this.init(force);
      }
      if (this.current === null) {
        this._resolvePromise(this._promise((function(_this) {
          return function() {
            if (_this.options.onStart != null) {
              return _this.options.onStart(_this);
            }
          };
        })(this)).then(function() {
          return this.showStep(0);
        }));
      }
      return this;
    };

    Tour.prototype.next = function() {
      return this._resolvePromise(this.hideStep(this.current).then(function() {
        return this._showNextStep;
      }));
    };

    Tour.prototype.prev = function() {
      return this._resolvePromise(this.hideStep(this.current).then(function() {
        return this._showPrevStep;
      }));
    };

    Tour.prototype.goTo = function(i) {
      return this._resolvePromise(this.hideStep(this.current).then(function() {
        return this.showStep(i);
      }));
    };

    Tour.prototype.end = function() {
      return this._resolvePromise(this.hideStep(this.current).then((function(_this) {
        return function() {
          $(document).off("click.tour-" + _this.options.name);
          $(document).off("keyup.tour-" + _this.options.name);
          $(window).off("resize.tour-" + _this.options.name);
          _this._setState('end', 'yes');
          _this.inited = false;
          _this.force = false;
          _this._clearTimer();
          if (_this.options.onEnd != null) {
            return _this.options.onEnd(_this);
          }
        };
      })(this)));
    };

    Tour.prototype.ended = function() {
      return !this.force && !!this._getState('end');
    };

    Tour.prototype.restart = function() {
      this._removeState('current_step');
      this._removeState('end');
      return this.start();
    };

    Tour.prototype.pause = function() {
      var step;
      step = this.step(this.current);
      if (!step || !step.options.duration) {
        return this;
      }
      this._paused = true;
      this._duration -= new Date().getTime() - this._start;
      window.clearTimeout(this._timer);
      this._debug("Paused/Stopped step " + (this.current + 1) + " timer (" + this._duration + " remaining).");
      if (step.options.onPause != null) {
        return step.options.onPause(this, this._duration);
      }
    };

    Tour.prototype.resume = function() {
      var step;
      step = this.step(this.current);
      if (!step || !step.options.duration) {
        return this;
      }
      this._paused = false;
      this._start = new Date().getTime();
      this._duration = this._duration || step.options.duration;
      this._timer = window.setTimeout((function(_this) {
        return function() {
          if (_this._isLast()) {
            return _this.next();
          } else {
            return _this.end();
          }
        };
      })(this), this._duration);
      this._debug("Started step " + (this.current + 1) + " timer with duration " + this._duration);
      if ((step.options.onResume != null) && this._duration !== step.options.duration) {
        return step.options.onResume(this, this._duration);
      }
    };

    Tour.prototype.hideStep = function(i) {
      var options, promise, step;
      step = this.step(i);
      if (!step) {
        return;
      }
      options = step.options;
      this._clearTimer();
      promise = this._promise((function(_this) {
        return function() {
          if (options.onHide != null) {
            return options.onHide(_this, i);
          }
        };
      })(this));
      if (options.backdrop) {
        this._hideBackdrop();
      }
      promise.then((function(_this) {
        return function(e) {
          var $element;
          $element = $(options.element);
          if (!($element.data('bs.popover') || $element.data('popover'))) {
            $element = $('body');
          }
          $element.popover('destroy').removeClass("tour-" + _this.options.name + "-element tour-" + _this.options.name + "-" + i + "-element");
          if (options.reflex) {
            $element.removeClass('tour-step-element-reflex').off("" + (_this._reflexEvent(options.reflex)) + ".tour-" + _this.options.name);
          }
          if (options.backdrop) {
            _this._hideStepBackdrop(options.element);
          }
          if (options.onHidden != null) {
            return options.onHidden(_this);
          }
        };
      })(this));
      this._resolvePromise(promise);
      return promise;
    };

    Tour.prototype.showStep = function(i) {
      var options, promise, skipToPrevious, step;
      if (this.ended()) {
        this._debug('Tour ended, showStep prevented.');
        return this;
      }
      step = this.step(i);
      if (!step) {
        return;
      }
      options = step.options;
      skipToPrevious = i < this.current;
      promise = this._promise((function(_this) {
        return function() {
          if (options.onShow != null) {
            return options.onShow(_this, i);
          }
        };
      })(this));
      promise.then((function(_this) {
        return function(e) {
          _this.currentStep(i);
          options.path = (function() {
            switch ({}.toString.call(options.path)) {
              case '[object Function]':
                return options.path();
              case '[object String]':
                return this.options.basePath + options.path;
              default:
                return options.path;
            }
          }).call(_this);
          if (_this._isRedirect(options.path, [document.location.pathname, document.location.hash].join(''))) {
            _this._redirect(options.redirect, options.path);
            return;
          }
          if (_this._isOrphan(options.element)) {
            if (!options.orphan) {
              _this._debug("Skip the orphan step " + (_this.current + 1) + ".\nOrphan option is false and the element does not exist or is hidden.");
              _this[skipToPrevious ? '_showPrevStep' : '_showNextStep']();
              return;
            }
            _this._debug("Show the orphan step " + (_this.current + 1) + ". Orphans option is true.");
          }
          if (options.backdrop) {
            _this._showBackdrop(!_this._isOrphan(options.element) ? options.element : void 0);
          }
          _this._scrollIntoView(options.element, function() {
            if (_this.currentStep() !== i) {
              return;
            }
            if ((options.element != null) && options.backdrop) {
              _this._showStepBackdrop(step);
            }
            _this._showPopover(step, i);
            if (options.onShown != null) {
              options.onShown(_this);
            }
            return _this._debug("Step " + (_this.current + 1) + " of " + _this.steps.length);
          });
          if (options.duration) {
            return _this.resume();
          }
        };
      })(this));
      if (options.delay) {
        this._debug("Wait " + options.delay + " milliseconds to show the step " + (this.current + 1));
        window.setTimeout((function(_this) {
          return function() {
            return _this._resolvePromise(promise);
          };
        })(this), options.delay);
      } else {
        this._resolvePromise(promise);
      }
      return promise;
    };

    Tour.prototype._setState = function(key, value) {
      var e, keyName;
      if (this.options.storage) {
        keyName = "" + this.options.name + "_" + key;
        try {
          this.options.storage.setItem(keyName, value);
        } catch (_error) {
          e = _error;
          if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
            this.debug('LocalStorage quota exceeded. State storage failed.');
          }
        }
        return this.options.afterSetState(keyName, value);
      } else {
        if (this._state == null) {
          this._state = {};
        }
        return this._state[key] = value;
      }
    };

    Tour.prototype._removeState = function(key) {
      var keyName;
      if (this.options.storage) {
        keyName = "" + this.options.name + "_" + key;
        this.options.storage.removeItem(keyName);
        return this.options.afterRemoveState(keyName);
      } else {
        if (this._state != null) {
          return delete this._state[key];
        }
      }
    };

    Tour.prototype._getState = function(key) {
      var keyName, value;
      if (this.options.storage) {
        keyName = "" + this.options.name + "_" + key;
        value = this.options.storage.getItem(keyName);
      } else {
        if (this._state != null) {
          value = this._state[key];
        }
      }
      if (value === void 0 || value === 'null') {
        value = null;
      }
      this.options.afterGetState(key, value);
      return value;
    };

    Tour.prototype._showNextStep = function() {
      var options, step;
      step = this.step(this.current);
      options = step.options;
      return this._resolvePromise(this._promise((function(_this) {
        return function() {
          if (options.onNext != null) {
            return options.onNext(_this);
          }
        };
      })(this)).then((function(_this) {
        return function() {
          return _this.showStep(_this.current + 1);
        };
      })(this)));
    };

    Tour.prototype._showPrevStep = function() {
      var options, step;
      step = this.step(this.current);
      options = step.options;
      return this._resolvePromise(this._promise((function(_this) {
        return function() {
          if (options.onPrev != null) {
            return options.onPrev(_this);
          }
        };
      })(this)).then((function(_this) {
        return function() {
          return _this.showStep(_this.current - 1);
        };
      })(this)));
    };

    Tour.prototype._debug = function(text) {
      if (this.options.debug) {
        return window.console.log("Bootstrap Tour '" + this.options.name + "' | " + text);
      }
    };

    Tour.prototype._isRedirect = function(path, currentPath) {
      return (path != null) && path !== '' && (({}.toString.call(path) === '[object RegExp]' && !path.test(currentPath)) || ({}.toString.call(path) === '[object String]' && path.replace(/\?.*$/, '').replace(/\/?$/, '') !== currentPath.replace(/\/?$/, '')));
    };

    Tour.prototype._redirect = function(redirect, path) {
      if ($.isFunction(redirect)) {
        return redirect.call(this, path);
      } else if (redirect === true) {
        this._debug("Redirect to " + path);
        return document.location.href = path;
      }
    };

    Tour.prototype._isOrphan = function(element) {
      var $element;
      if (element != null) {
        return false;
      }
      $element = $(element);
      return !$element.length || $element.is(':hidden') && $element[0].namespaceURI !== 'http://www.w3.org/2000/svg';
    };

    Tour.prototype._isLast = function() {
      return this.current < this.steps.length - 1;
    };

    Tour.prototype._showPopover = function(step, i) {
      var $element, $tip, isOrphan, options;
      options = step.options;
      $(".tour-" + this.options.name).remove();
      isOrphan = this._isOrphan(options.element);
      options.template = this._template(step, i);
      if (isOrphan) {
        options.element = 'body';
        options.placement = 'top';
      }
      $element = $(options.element);
      $element.addClass("tour-" + this.options.name + "-element tour-" + this.options.name + "-" + i + "-element");
      if (options.reflex && !isOrphan) {
        $element.addClass('tour-step-element-reflex');
        $element.off("" + (this._reflexEvent(options.reflex)) + ".tour-" + this.options.name);
        $element.on("" + (this._reflexEvent(options.reflex)) + ".tour-" + this.options.name, (function(_this) {
          return function() {
            if (_this._isLast()) {
              return _this.next();
            } else {
              return _this.end();
            }
          };
        })(this));
      }
      $element.popover({
        placement: options.placement,
        trigger: 'manual',
        title: options.title,
        content: options.content,
        html: true,
        animation: options.animation,
        container: options.container,
        template: options.template,
        selector: options.element
      }).popover('show');
      $tip = $element.data('bs.popover') ? $element.data('bs.popover').tip() : $element.data('popover').tip();
      $tip.attr('id', "tour-step-" + i + "-tooltip");
      this._reposition($tip, options.placement);
      if (isOrphan) {
        return this._center($tip);
      }
    };

    Tour.prototype._template = function(step, i) {
      var $navigation, $next, $prev, $template, options;
      options = step.options;
      $template = $.isFunction(options.template) ? $(options.template(i, step)) : $(options.template);
      $navigation = $template.find('.popover-navigation');
      $prev = $navigation.find('[data-role="prev"]');
      $next = $navigation.find('[data-role="next"]');
      if (this._isOrphan(options.element)) {
        $template.addClass('orphan');
      }
      $template.addClass("tour-" + this.options.name + " tour-" + this.options.name + "-" + i);
      if (i === 0) {
        $navigation.find('[data-role="prev"]').addClass('disabled');
      }
      if (i === this.steps.length - 1) {
        $navigation.find('[data-role="next"]').addClass('disabled');
      }
      if (!options.duration) {
        $navigation.find('[data-role="pause-resume"]').remove();
      }
      return $template.clone().wrap('<div>').parent().html();
    };

    Tour.prototype._reflexEvent = function(reflex) {
      if ({}.toString.call(reflex) === '[object Boolean]') {
        return 'click';
      } else {
        return reflex;
      }
    };

    Tour.prototype._reposition = function($tip, placement) {
      var offsetBottom, offsetHeight, offsetRight, offsetWidth, originalLeft, originalTop, tipOffset;
      offsetWidth = $tip[0].offsetWidth;
      offsetHeight = $tip[0].offsetHeight;
      tipOffset = $tip.offset();
      originalLeft = tipOffset.left;
      originalTop = tipOffset.top;
      offsetBottom = $(document).outerHeight() - tipOffset.top - $tip.outerHeight();
      if (offsetBottom < 0) {
        tipOffset.top = tipOffset.top + offsetBottom;
      }
      offsetRight = $('html').outerWidth() - tipOffset.left - $tip.outerWidth();
      if (offsetRight < 0) {
        tipOffset.left = tipOffset.left + offsetRight;
      }
      if (tipOffset.top < 0) {
        tipOffset.top = 0;
      }
      if (tipOffset.left < 0) {
        tipOffset.left = 0;
      }
      $tip.offset(tipOffset);
      if (placement === 'bottom' || placement === 'top') {
        if (originalLeft !== tipOffset.left) {
          return this._replaceArrow($tip, (tipOffset.left - originalLeft) * 2, offsetWidth, 'left');
        }
      } else {
        if (originalTop !== tipOffset.top) {
          return this._replaceArrow($tip, (tipOffset.top - originalTop) * 2, offsetHeight, 'top');
        }
      }
    };

    Tour.prototype._center = function($tip) {
      return $tip.css('top', $(window).outerHeight() / 2 - $tip.outerHeight() / 2);
    };

    Tour.prototype._replaceArrow = function($tip, delta, dimension, position) {
      return $tip.find('.arrow').css(position, delta ? 50 * (1 - delta / dimension) + '%' : '');
    };

    Tour.prototype._scrollIntoView = function(element, callback) {
      var $element, $window, counter, offsetTop, scrollTop, windowHeight;
      $element = $(element);
      if (!$element.length) {
        return callback();
      }
      $window = $(window);
      windowHeight = $window.height();
      offsetTop = $element.offset().top;
      scrollTop = Math.ceil(Math.max(0, offsetTop - (windowHeight / 2)));
      counter = 0;
      this._debug("Scroll into view. ScrollTop: " + scrollTop + ". Element offset: " + offsetTop + ". Window height: " + windowHeight + ".");
      return $('body, html').stop(true, true).animate({
        scrollTop: scrollTop
      }, (function(_this) {
        return function() {
          if (++counter === 2) {
            callback();
            return _this._debug("Scroll into view.\nAnimation end element offset: " + ($element.offset().top) + ".\nWindow height: " + ($window.height()) + ".");
          }
        };
      })(this));
    };

    Tour.prototype._onResize = function(callback, timeout) {
      return $(window).on("resize.tour-" + this.options.name, function() {
        clearTimeout(timeout);
        return timeout = setTimeout(callback, 100);
      });
    };

    Tour.prototype._mouse = function() {
      var _this;
      _this = this;
      return $(document).off("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='prev']").off("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='next']").off("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='end']").off("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='pause-resume']").on("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='next']", (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.next();
        };
      })(this)).on("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='prev']", (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.prev();
        };
      })(this)).on("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='end']", (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.end();
        };
      })(this)).on("click.tour-" + this.options.name, ".popover.tour-" + this.options.name + " *[data-role='pause-resume']", function(e) {
        var $this;
        e.preventDefault();
        $this = $(this);
        $this.text(_this._paused ? $this.data('pause-text') : $this.data('resume-text'));
        if (_this._paused) {
          return _this.resume();
        } else {
          return _this.pause();
        }
      });
    };

    Tour.prototype._keyboard = function() {
      if (typeof value === 'undefined') {
        return this.options.keyboard;
      }
      return $(document).off("keyup.tour-" + this.options.name).on("keyup.tour-" + this.options.name, (function(_this) {
        return function(e) {
          if (!e.which) {
            return;
          }
          switch (e.which) {
            case 39:
              e.preventDefault();
              if (_this._isLast()) {
                return _this.next();
              } else {
                return _this.end();
              }
              break;
            case 37:
              e.preventDefault();
              if (_this.current > 0) {
                return _this.prev();
              }
              break;
            case 27:
              e.preventDefault();
              return _this.end();
          }
        };
      })(this));
    };

    Tour.prototype._promise = function(fn) {
      var deferred;
      deferred = new $.Deferred();
      if ($.isFunction(fn)) {
        deferred.then(function() {
          return fn;
        });
      }
      return deferred;
    };

    Tour.prototype._resolvePromise = function(deferred) {
      return deferred.resolve();
    };

    Tour.prototype._showBackdrop = function() {
      if (this.$backdrop && this.$backdrop.length) {
        return;
      }
      return this.$backdrop = $('<div>', {
        "class": 'tour-backdrop'
      }).appendTo('body');
    };

    Tour.prototype._showStepBackdrop = function(step) {
      var $element, options;
      options = step.options;
      $element = $(options.element);
      if (!$element.length || (this.$backdropOverlay && this.$backdropOverlay.length)) {
        return;
      }
      $element.addClass('tour-backdrop-step');
      return this.$backdropOverlay = $('<div>', (function() {
        var data, padding;
        data = {
          "class": 'tour-backdrop-step-overlay',
          width: $element.innerWidth(),
          height: $element.innerHeight(),
          offset: $element.offset()
        };
        padding = options.backdropPadding;
        if (padding) {
          if (typeof padding === 'object') {
            if (padding.top == null) {
              padding.top = 0;
            }
            if (padding.right == null) {
              padding.right = 0;
            }
            if (padding.bottom == null) {
              padding.bottom = 0;
            }
            if (padding.left == null) {
              padding.left = 0;
            }
            data.offset.top = data.offset.top - padding.top;
            data.offset.left = data.offset.left - padding.left;
            data.width = data.width + padding.left + padding.right;
            data.height = data.height + padding.top + padding.bottom;
          } else {
            data.offset.top = data.offset.top - padding;
            data.offset.left = data.offset.left - padding;
            data.width = data.width + (padding * 2);
            data.height = data.height + (padding * 2);
          }
        }
        return data;
      })()).appendTo('body');
    };

    Tour.prototype._hideBackdrop = function() {
      if (this.$backdrop && this.$backdrop.length) {
        return this.$backdrop.remove();
      }
    };

    Tour.prototype._hideStepBackdrop = function(element) {
      var $element;
      $element = $(element);
      if (!$element.length || (!this.$backdropOverlay || !this.$backdropOverlay.length)) {
        return;
      }
      $element.removeClass('tour-backdrop-step');
      return this.$backdropOverlay.remove();
    };

    Tour.prototype._clearTimer = function() {
      window.clearTimeout(this._timer);
      this._timer = null;
      return this._duration = null;
    };

    return Tour;

  })();
  TourStep = (function() {
    function TourStep(options) {
      if (options == null) {
        options = {};
      }
      this.options = $.extend({}, TourStep.defaults, options);
    }

    return TourStep;

  })();
  window.Tour = Tour;
  window.TourStep = TourStep;
  window.Tour.defaults = {
    name: 'tour',
    steps: [],
    basePath: '',
    storage: (function() {
      var storage;
      try {
        storage = window.localStorage;
      } catch (_error) {
        storage = false;
      }
      return storage;
    })(),
    debug: false,
    afterSetState: function(key, value) {},
    afterGetState: function(key, value) {},
    afterRemoveState: function(key) {},
    onStart: function(tour) {},
    onEnd: function(tour) {}
  };
  return window.TourStep.defaults = {
    path: '',
    placement: 'right',
    title: '',
    content: '<p></p>',
    animation: true,
    container: 'body',
    keyboard: true,
    backdrop: false,
    backdropPadding: 0,
    redirect: true,
    orphan: false,
    duration: false,
    delay: false,
    template: '<div class="popover" role="tooltip"> <div class="arrow"></div> <h3 class="popover-title"></h3> <div class="popover-content"></div> <div class="popover-navigation"> <div class="btn-group"> <button class="btn btn-sm btn-default" data-role="prev">&laquo; Prev</button> <button class="btn btn-sm btn-default" data-role="next">Next &raquo;</button> <button class="btn btn-sm btn-default" data-role="pause-resume" data-pause-text="Pause" data-resume-text="Resume">Pause</button> </div> <button class="btn btn-sm btn-default" data-role="end">End tour</button> </div> </div>',
    onShow: function(tour) {},
    onShown: function(tour) {},
    onHide: function(tour) {},
    onHidden: function(tour) {},
    onNext: function(tour) {},
    onPrev: function(tour) {},
    onPause: function(tour, duration) {},
    onResume: function(tour, duration) {}
  };
})(window.jQuery, window);

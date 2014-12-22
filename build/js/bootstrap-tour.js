/* ========================================================================
 * bootstrap-tour - v0.10.0
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
      this.$backdropStep = null;
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

    Tour.prototype.step = function(index) {
      return this.steps[index];
    };

    Tour.prototype.currentStep = function(index, $element) {
      if (typeof index === 'undefined') {
        return this.current;
      }
      this.current = index;
      return this._setState('current_step', index);
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
      this._mouse();
      this._keyboard();
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
      var promise;
      if (force == null) {
        force = false;
      }
      if (!this.inited) {
        this.init(force);
      }
      if (this.current == null) {
        promise = this._promise((function(_this) {
          return function() {
            var _base;
            return typeof (_base = _this.options).onStart === "function" ? _base.onStart(_this) : void 0;
          };
        })(this));
        promise.then((function(_this) {
          return function() {
            return _this.showStep(0);
          };
        })(this));
        promise.resolve();
      }
      return this;
    };

    Tour.prototype.next = function() {
      var promise;
      promise = this.hideStep(this.current);
      promise.then((function(_this) {
        return function() {
          return _this._nextStep();
        };
      })(this));
      return promise.resolve();
    };

    Tour.prototype.prev = function() {
      var promise;
      promise = this.hideStep(this.current);
      promise.then((function(_this) {
        return function() {
          return _this._prevStep();
        };
      })(this));
      return promise.resolve();
    };

    Tour.prototype.goTo = function(i) {
      var promise;
      promise = this.hideStep(this.current);
      promise.then((function(_this) {
        return function() {
          return _this.showStep(i);
        };
      })(this));
      return promise.resolve();
    };

    Tour.prototype.end = function() {
      var promise;
      promise = this.hideStep(this.current);
      promise.then((function(_this) {
        return function() {
          var _base;
          $(document).off("click.tour-" + _this.options.name);
          $(document).off("keyup.tour-" + _this.options.name);
          $(window).off("resize.tour-" + _this.options.name);
          _this._setState('end', 'yes');
          _this.inited = false;
          _this.force = false;
          _this._clearTimer();
          return typeof (_base = _this.options).onEnd === "function" ? _base.onEnd(_this) : void 0;
        };
      })(this));
      return promise.resolve();
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
      var step, _base;
      step = this.step(this.current);
      if (!step || !step.options.duration) {
        return this;
      }
      this._paused = true;
      this._duration -= new Date().getTime() - this._start;
      window.clearTimeout(this._timer);
      this._debug("Paused/Stopped step " + (this.current + 1) + " timer (" + this._duration + " remaining).");
      return typeof (_base = step.options).onPause === "function" ? _base.onPause(this, this._duration) : void 0;
    };

    Tour.prototype.resume = function() {
      var step, _base;
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
      if (this._duration !== step.options.duration) {
        return typeof (_base = step.options).onResume === "function" ? _base.onResume(this, this._duration) : void 0;
      }
    };

    Tour.prototype.hideStep = function(i) {
      var promise, step;
      step = this.step(i);
      if (!step) {
        return;
      }
      this._clearTimer();
      promise = this._promise((function(_this) {
        return function() {
          var _base;
          return typeof (_base = step.options).onHide === "function" ? _base.onHide(_this, i) : void 0;
        };
      })(this));
      this._disableBackdrop(step);
      promise.then((function(_this) {
        return function(e) {
          var $element, _base;
          $element = $(step.options.element);
          if (!($element.data('bs.popover') || $element.data('popover'))) {
            $element = $('body');
          }
          $element.popover('destroy').removeClass("tour-" + _this.options.name + "-element tour-" + _this.options.name + "-" + i + "-element");
          if (step.options.reflex) {
            $element.removeClass('tour-step-element-reflex').off("" + (_this._reflexEvent(step.options.reflex)) + ".tour-" + _this.options.name);
          }
          _this._disableStepBackdrop(step);
          return typeof (_base = step.options).onHidden === "function" ? _base.onHidden(_this) : void 0;
        };
      })(this));
      promise.resolve();
      return promise;
    };

    Tour.prototype.showStep = function(i) {
      var promise, skipToPrevious, step;
      if (this.ended()) {
        this._debug('Tour ended, showStep prevented.');
        return this;
      }
      step = this.step(i);
      if (!step) {
        return;
      }
      skipToPrevious = i < this.current;
      promise = this._promise((function(_this) {
        return function() {
          var _base;
          return typeof (_base = step.options).onShow === "function" ? _base.onShow(_this, i) : void 0;
        };
      })(this));
      promise.then((function(_this) {
        return function(e) {
          var showPopoverAndOverlay;
          showPopoverAndOverlay = function() {
            var _base;
            if (_this.current !== i) {
              return;
            }
            _this._showPopover(step, i);
            if (typeof (_base = step.options).onShown === "function") {
              _base.onShown(_this);
            }
            return _this._debug("Step " + (_this.current + 1) + "/" + _this.steps.length);
          };
          _this.currentStep(i);
          step.options.path = (function() {
            switch ({}.toString.call(step.options.path)) {
              case '[object Function]':
                return step.options.path();
              case '[object String]':
                return this.options.basePath + step.options.path;
              default:
                return step.options.path;
            }
          }).call(_this);
          if (_this._isRedirect(step.options.path, [document.location.pathname, document.location.hash].join(''))) {
            _this._redirect(step.options.redirect, step.options.path);
            return;
          }
          if (_this._isOrphan(step)) {
            if (!step.options.orphan) {
              _this._debug("Skip the orphan step " + (_this.current + 1) + ".\nOrphan option is false and the element does not exist or is hidden.");
              _this[skipToPrevious ? '_prevStep' : '_nextStep']();
              return;
            }
            _this._debug("Show the orphan step " + (_this.current + 1) + ". Orphans option is true.");
          }
          _this._enableBackdrop(step);
          _this._scroll(step.options.element, function() {
            if (_this.current !== i) {
              return;
            }
            return _this._enableStepBackdrop(step);
          });
          if (step.options.autoscroll) {
            _this._scroll(step.options.element, showPopoverAndOverlay);
          } else {
            showPopoverAndOverlay();
          }
          if (step.options.duration) {
            return _this.resume();
          }
        };
      })(this));
      window.setTimeout(function() {
        if (step.options.delay) {
          this._debug("Step " + (this.current + 1) + " showing delayed of " + step.options.delay + "ms");
        }
        return promise.resolve();
      }, step.options.delay);
      return promise;
    };

    Tour.prototype._setState = function(key, value) {
      var e, keyName, _base;
      if (this.options.storage) {
        keyName = "" + this.options.name + "_" + key;
        try {
          this.options.storage.setItem(keyName, value);
        } catch (_error) {
          e = _error;
          if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
            this.debug('Quota exceeded. State storage failed.');
          }
        }
        return typeof (_base = this.options).afterSetState === "function" ? _base.afterSetState(keyName, value) : void 0;
      } else {
        if (this._state == null) {
          this._state = {};
        }
        return this._state[key] = value;
      }
    };

    Tour.prototype._removeState = function(key) {
      var keyName, _base;
      if (this.options.storage) {
        keyName = "" + this.options.name + "_" + key;
        this.options.storage.removeItem(keyName);
        return typeof (_base = this.options).afterRemoveState === "function" ? _base.afterRemoveState(keyName) : void 0;
      } else {
        if (this._state != null) {
          return this._state[key] = null;
        }
      }
    };

    Tour.prototype._getState = function(key) {
      var keyName, value, _base;
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
      if (typeof (_base = this.options).afterGetState === "function") {
        _base.afterGetState(key, value);
      }
      return value;
    };

    Tour.prototype._nextStep = function() {
      var promise, step;
      step = this.step(this.current);
      promise = this._promise((function(_this) {
        return function() {
          var _base;
          return typeof (_base = step.options).onNext === "function" ? _base.onNext(_this) : void 0;
        };
      })(this));
      promise.then((function(_this) {
        return function() {
          return _this.showStep(_this.current + 1);
        };
      })(this));
      return promise.resolve();
    };

    Tour.prototype._prevStep = function() {
      var promise, step;
      step = this.step(this.current);
      promise = this._promise((function(_this) {
        return function() {
          var _base;
          return typeof (_base = step.options).onPrev === "function" ? _base.onPrev(_this) : void 0;
        };
      })(this));
      promise.then((function(_this) {
        return function() {
          return _this.showStep(_this.current - 1);
        };
      })(this));
      return promise.resolve();
    };

    Tour.prototype._debug = function(text) {
      if (this.options.debug) {
        return window.console.log("Bootstrap Tour `" + this.options.name + "`: " + text);
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

    Tour.prototype._isOrphan = function(step) {
      var $element;
      if (step.options.element != null) {
        return false;
      }
      $element = $(step.options.element);
      return !$element.length || $element.is(':hidden') && $element[0].namespaceURI !== 'http://www.w3.org/2000/svg';
    };

    Tour.prototype._isLast = function() {
      return this.current < this.steps.length - 1;
    };

    Tour.prototype._showPopover = function(step, i) {
      var $element, $tip, isOrphan;
      $(".tour-" + this.options.name).remove();
      isOrphan = this._isOrphan(step);
      step.options.template = this._template(step, i);
      if (isOrphan) {
        step.options.element = 'body';
        step.options.placement = 'top';
      }
      $element = $(step.options.element);
      $element.addClass("tour-" + this.options.name + "-element tour-" + this.options.name + "-" + i + "-element");
      if (step.options.reflex && !isOrphan) {
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
        placement: step.options.placement,
        trigger: 'manual',
        title: step.options.title,
        content: step.options.content,
        html: true,
        animation: step.options.animation,
        container: step.options.container,
        template: step.options.template,
        selector: step.options.element
      }).popover('show');
      $tip = $element.data($element.data('bs.popover') ? 'bs.popover' : 'popover').tip();
      $tip.attr('id', "tour-step-" + i + "-tooltip");
      this._reposition($tip, step.options.placement);
      if (isOrphan) {
        return this._center($tip);
      }
    };

    Tour.prototype._template = function(step, i) {
      var $navigation, $next, $prev, $template;
      $template = $.isFunction(step.options.template) ? $(step.options.template(i, step)) : $(step.options.template);
      $navigation = $template.find('.popover-navigation');
      $prev = $navigation.find('[data-role="prev"]');
      $next = $navigation.find('[data-role="next"]');
      if (this._isOrphan(step)) {
        $template.addClass('orphan');
      }
      $template.addClass("tour-" + this.options.name + " tour-" + this.options.name + "-" + i);
      if (i === 0) {
        $navigation.find('[data-role="prev"]').addClass('disabled');
      }
      if (i === this.steps.length - 1) {
        $navigation.find('[data-role="next"]').addClass('disabled');
      }
      if (!step.options.duration) {
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

    Tour.prototype._scroll = function(element, callback) {
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
      this._debug("Scroll. Scroll top: " + scrollTop + ". Element Offset: " + offsetTop + ". Window height: " + windowHeight + ".");
      return $('body, html').stop(true, true).animate({
        scrollTop: scrollTop
      }, (function(_this) {
        return function() {
          if (++counter === 2) {
            callback();
            return _this._debug("Scroll.\nAnimation end element offset: " + ($element.offset().top) + ".\nWindow height: " + ($window.height()) + ".");
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
      if (!this.options.keyboard) {
        return;
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

    Tour.prototype._enableBackdrop = function(step) {
      if (step.options.backdrop && !this.$backdrop && !this._isOrphan(step)) {
        return this.$backdrop = $('<div>', {
          "class": 'tour-backdrop'
        }).appendTo('body');
      }
    };

    Tour.prototype._enableStepBackdrop = function(step) {
      var $element;
      if (!step.options.backdrop || (step.options.element == null)) {
        return;
      }
      $element = $(step.options.element);
      if (!$element.length || this.$backdropStep) {
        return;
      }
      $element.addClass('tour-backdrop-step');
      return this.$backdropStep = $('<div>', (function() {
        var data, padding;
        data = {
          "class": 'tour-backdrop-step-overlay',
          width: $element.innerWidth(),
          height: $element.innerHeight(),
          offset: $element.offset()
        };
        padding = step.options.backdropPadding;
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

    Tour.prototype._disableBackdrop = function(step) {
      if (!step.options.backdrop || !this.$backdrop) {
        return;
      }
      this.$backdrop.remove();
      return this.$backdrop = null;
    };

    Tour.prototype._disableStepBackdrop = function(step) {
      var $element;
      if (step.options.backdrop || !this.$backdropStep) {
        return;
      }
      $element = $(step.options.element);
      if (!$element.length) {
        return;
      }
      $element.removeClass('tour-backdrop-step');
      this.$backdropStep.remove();
      return this.$backdropStep = null;
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
    afterSetState: null,
    afterGetState: null,
    afterRemoveState: null,
    onStart: null,
    onEnd: null
  };
  return window.TourStep.defaults = {
    path: '',
    placement: 'right',
    title: '',
    content: '<p></p>',
    animation: true,
    container: 'body',
    autoscroll: true,
    keyboard: true,
    backdrop: false,
    backdropPadding: 0,
    redirect: true,
    orphan: false,
    duration: false,
    delay: 0,
    element: null,
    template: '<div class="popover" role="tooltip"> <div class="arrow"></div> <h3 class="popover-title"></h3> <div class="popover-content"></div> <div class="popover-navigation"> <div class="btn-group"> <button class="btn btn-sm btn-default" data-role="prev">&laquo; Prev</button> <button class="btn btn-sm btn-default" data-role="next">Next &raquo;</button> <button class="btn btn-sm btn-default" data-role="pause-resume" data-pause-text="Pause" data-resume-text="Resume">Pause</button> </div> <button class="btn btn-sm btn-default" data-role="end">End tour</button> </div> </div>',
    onShow: null,
    onShown: null,
    onHide: null,
    onHidden: null,
    onNext: null,
    onPrev: null,
    onPause: null,
    onResume: null
  };
})(window.jQuery, window);

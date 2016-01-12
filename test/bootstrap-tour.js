/* ========================================================================
 * bootstrap-tour - v0.10.2
 * http://bootstraptour.com
 * ========================================================================
 * Copyright 2012-2015 Ulrich Sossou
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

(function($, window) {
  var Tour, document;
  document = window.document;
  Tour = (function() {
    function Tour(options) {
      var storage;
      try {
        storage = window.localStorage;
      } catch (_error) {
        storage = false;
      }
      this._options = $.extend({
        name: 'tour',
        steps: [],
        container: 'body',
        autoscroll: true,
        keyboard: true,
        storage: storage,
        debug: false,
        mustFinish: false,
        backdrop: false,
        backdropContainer: 'body',
        backdropPadding: 0,
        redirect: true,
        frozenContext: {},
        orphan: false,
        duration: false,
        delay: false,
        basePath: '',
        template: '<div class="popover" role="tooltip"> <div class="arrow"></div> <h3 class="popover-title"></h3> <div class="popover-content"></div> <div class="popover-navigation"> <div class="btn-group"> <button class="btn btn-sm btn-default" data-role="prev">&laquo; Prev</button> <button class="btn btn-sm btn-default" data-role="next">Next &raquo;</button> <button class="btn btn-sm btn-default" data-role="pause-resume" data-pause-text="Pause" data-resume-text="Resume">Pause</button> </div> <button class="btn btn-sm btn-default" data-role="end">End tour</button> </div> </div>',
        afterSetState: function(key, value) {},
        afterGetState: function(key, value) {},
        afterRemoveState: function(key) {},
        onStart: function(tour) {},
        onEnd: function(tour) {},
        onShow: function(tour) {},
        onShown: function(tour) {},
        onHide: function(tour) {},
        onHidden: function(tour) {},
        onNext: function(tour) {},
        onPrev: function(tour) {},
        onPause: function(tour, duration) {},
        onResume: function(tour, duration) {},
        onRedirectError: function(tour) {}
      }, options);
      this._force = false;
      this._inited = false;
      this._current = null;
      this.backdrop = {
        overlay: null,
        $element: null,
        $background: null,
        backgroundShown: false,
        overlayElementShown: false
      };
      this;
    }

    Tour.prototype.unfreeze = function() {
      $('.popover-navigation button').prop('disabled', false);
      $('.popover-navigation button').removeClass('disabled');
      if (this._current < 1) {
        $('.popover-navigation [data-role="prev"]').prop('disabled', true);
        $('.popover-navigation [data-role="prev"]').addClass('disabled');
      }
      if (this._current >= this._options.steps.length - 1) {
        $('.popover-navigation [data-role="next"]').prop('disabled', true);
        return $('.popover-navigation [data-role="next"]').addClass('disabled');
      }
    };

    Tour.prototype.addSteps = function(steps) {
      var step, _i, _len;
      for (_i = 0, _len = steps.length; _i < _len; _i++) {
        step = steps[_i];
        this.addStep(step);
      }
      return this;
    };

    Tour.prototype.addStep = function(step) {
      this._options.steps.push(step);
      return this;
    };

    Tour.prototype.getStep = function(i) {
      if (this._options.steps[i] != null) {
        return $.extend({
          id: "step-" + i,
          path: '',
          host: '',
          placement: 'right',
          title: '',
          content: '<p></p>',
          next: i === this._options.steps.length - 1 ? -1 : i + 1,
          prev: i - 1,
          animation: true,
          container: this._options.container,
          autoscroll: this._options.autoscroll,
          backdrop: this._options.backdrop,
          backdropContainer: this._options.backdropContainer,
          backdropPadding: this._options.backdropPadding,
          redirect: this._options.redirect,
          reflexElement: this._options.steps[i].element,
          orphan: this._options.orphan,
          duration: this._options.duration,
          delay: this._options.delay,
          template: this._options.template,
          onShow: this._options.onShow,
          onShown: this._options.onShown,
          onHide: this._options.onHide,
          onHidden: this._options.onHidden,
          isFrozen: this._options.isFrozen || function() {},
          frozenContext: this._options.frozenContext,
          onNext: this._options.onNext,
          onPrev: this._options.onPrev,
          onPause: this._options.onPause,
          onResume: this._options.onResume,
          onRedirectError: this._options.onRedirectError
        }, this._options.steps[i]);
      }
    };

    Tour.prototype.init = function(force) {
      this._force = force;
      if (this.ended()) {
        this._debug('Tour ended, init prevented.');
        return this;
      }
      this.setCurrentStep();
      this._initMouseNavigation();
      this._initKeyboardNavigation();
      this._onResize((function(_this) {
        return function() {
          return _this.showStep(_this._current);
        };
      })(this));
      if (this._current !== null) {
        this.showStep(this._current);
      }
      this._inited = true;
      return this;
    };

    Tour.prototype.start = function(force) {
      var promise;
      if (force == null) {
        force = false;
      }
      if (!this._inited) {
        this.init(force);
      }
      if (this._current === null) {
        promise = this._makePromise(this._options.onStart != null ? this._options.onStart(this) : void 0);
        this._callOnPromiseDone(promise, this.showStep, 0);
      }
      return this;
    };

    Tour.prototype.next = function() {
      var promise;
      promise = this.hideStep(this._current);
      return this._callOnPromiseDone(promise, this._showNextStep);
    };

    Tour.prototype.prev = function() {
      var promise;
      promise = this.hideStep(this._current);
      return this._callOnPromiseDone(promise, this._showPrevStep);
    };

    Tour.prototype.goTo = function(i) {
      var promise;
      promise = this.hideStep(this._current);
      return this._callOnPromiseDone(promise, this.showStep, i);
    };

    Tour.prototype.end = function() {
      var endHelper, promise;
      endHelper = (function(_this) {
        return function(e) {
          $(document).off("click.tour-" + _this._options.name);
          $(document).off("keyup.tour-" + _this._options.name);
          $(window).off("resize.tour-" + _this._options.name);
          _this._setState('end', 'yes');
          _this._inited = false;
          _this._force = false;
          _this._clearTimer();
          if (_this._options.onEnd != null) {
            return _this._options.onEnd(_this);
          }
        };
      })(this);
      promise = this.hideStep(this._current);
      return this._callOnPromiseDone(promise, endHelper);
    };

    Tour.prototype.ended = function() {
      return !this._force && !!this._getState('end');
    };

    Tour.prototype.restart = function() {
      this._removeState('current_step');
      this._removeState('end');
      this._removeState('redirect_to');
      return this.start();
    };

    Tour.prototype.pause = function() {
      var step;
      step = this.getStep(this._current);
      if (!(step && step.duration)) {
        return this;
      }
      this._paused = true;
      this._duration -= new Date().getTime() - this._start;
      window.clearTimeout(this._timer);
      this._debug("Paused/Stopped step " + (this._current + 1) + " timer (" + this._duration + " remaining).");
      if (step.onPause != null) {
        return step.onPause(this, this._duration);
      }
    };

    Tour.prototype.resume = function() {
      var step;
      step = this.getStep(this._current);
      if (!(step && step.duration)) {
        return this;
      }
      this._paused = false;
      this._start = new Date().getTime();
      this._duration = this._duration || step.duration;
      this._timer = window.setTimeout((function(_this) {
        return function() {
          if (_this._isLast()) {
            return _this.next();
          } else {
            return _this.end();
          }
        };
      })(this), this._duration);
      this._debug("Started step " + (this._current + 1) + " timer with duration " + this._duration);
      if ((step.onResume != null) && this._duration !== step.duration) {
        return step.onResume(this, this._duration);
      }
    };

    Tour.prototype.hideStep = function(i) {
      var hideStepHelper, promise, step;
      step = this.getStep(i);
      if (!step) {
        return;
      }
      this._clearTimer();
      promise = this._makePromise(step.onHide != null ? step.onHide(this, i) : void 0);
      hideStepHelper = (function(_this) {
        return function(e) {
          var $element;
          $element = $(step.element);
          if (!($element.data('bs.popover') || $element.data('popover'))) {
            $element = $('body');
          }
          $element.popover('destroy').removeClass("tour-" + _this._options.name + "-element tour-" + _this._options.name + "-" + i + "-element");
          $element.removeData('bs.popover');
          if (step.reflex) {
            $(step.reflexElement).removeClass('tour-step-element-reflex').off("" + (_this._reflexEvent(step.reflex)) + ".tour-" + _this._options.name);
          }
          if (step.backdrop) {
            _this._hideBackdrop();
          }
          if (step.onHidden != null) {
            return step.onHidden(_this);
          }
        };
      })(this);
      this._callOnPromiseDone(promise, hideStepHelper);
      return promise;
    };

    Tour.prototype.showStep = function(i) {
      var promise, showStepHelper, skipToPrevious, step;
      if (this.ended()) {
        this._debug('Tour ended, showStep prevented.');
        return this;
      }
      step = this.getStep(i);
      if (!step) {
        return;
      }
      skipToPrevious = i < this._current;
      promise = this._makePromise(step.onShow != null ? step.onShow(this, i) : void 0);
      showStepHelper = (function(_this) {
        return function(e) {
          var path, showPopoverAndOverlay;
          _this.setCurrentStep(i);
          path = (function() {
            switch ({}.toString.call(step.path)) {
              case '[object Function]':
                return step.path();
              case '[object String]':
                return this._options.basePath + step.path;
              default:
                return step.path;
            }
          }).call(_this);
          if (_this._isRedirect(step.host, path, document.location)) {
            _this._redirect(step, i, path);
            if (!_this._isJustPathHashDifferent(step.host, path, document.location)) {
              return;
            }
          }
          if (_this._isOrphan(step)) {
            if (step.orphan === false) {
              _this._debug("Skip the orphan step " + (_this._current + 1) + ".\nOrphan option is false and the element does not exist or is hidden.");
              if (skipToPrevious) {
                _this._showPrevStep();
              } else {
                _this._showNextStep();
              }
              return;
            }
            _this._debug("Show the orphan step " + (_this._current + 1) + ". Orphans option is true.");
          }
          if (step.backdrop) {
            _this._showBackdrop(step);
          }
          showPopoverAndOverlay = function() {
            if (_this.getCurrentStep() !== i || _this.ended()) {
              return;
            }
            if ((step.element != null) && step.backdrop) {
              _this._showOverlayElement(step);
            }
            _this._showPopover(step, i);
            if (step.onShown != null) {
              step.onShown(_this);
            }
            return _this._debug("Step " + (_this._current + 1) + " of " + _this._options.steps.length);
          };
          if (step.autoscroll) {
            _this._scrollIntoView(step.element, showPopoverAndOverlay);
          } else {
            showPopoverAndOverlay();
          }
          if (step.duration) {
            return _this.resume();
          }
        };
      })(this);
      if (step.delay) {
        this._debug("Wait " + step.delay + " milliseconds to show the step " + (this._current + 1));
        window.setTimeout((function(_this) {
          return function() {
            return _this._callOnPromiseDone(promise, showStepHelper);
          };
        })(this), step.delay);
      } else {
        this._callOnPromiseDone(promise, showStepHelper);
      }
      return promise;
    };

    Tour.prototype.getCurrentStep = function() {
      return this._current;
    };

    Tour.prototype.setCurrentStep = function(value) {
      if (value != null) {
        this._current = value;
        this._setState('current_step', value);
      } else {
        this._current = this._getState('current_step');
        this._current = this._current === null ? null : parseInt(this._current, 10);
      }
      return this;
    };

    Tour.prototype.redraw = function() {
      return this._showOverlayElement(this.getStep(this.getCurrentStep()).element, true);
    };

    Tour.prototype._setState = function(key, value) {
      var e, keyName;
      if (this._options.storage) {
        keyName = "" + this._options.name + "_" + key;
        try {
          this._options.storage.setItem(keyName, value);
        } catch (_error) {
          e = _error;
          if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
            this._debug('LocalStorage quota exceeded. State storage failed.');
          }
        }
        return this._options.afterSetState(keyName, value);
      } else {
        if (this._state == null) {
          this._state = {};
        }
        return this._state[key] = value;
      }
    };

    Tour.prototype._removeState = function(key) {
      var keyName;
      if (this._options.storage) {
        keyName = "" + this._options.name + "_" + key;
        this._options.storage.removeItem(keyName);
        return this._options.afterRemoveState(keyName);
      } else {
        if (this._state != null) {
          return delete this._state[key];
        }
      }
    };

    Tour.prototype._getState = function(key) {
      var keyName, value;
      if (this._options.storage) {
        keyName = "" + this._options.name + "_" + key;
        value = this._options.storage.getItem(keyName);
      } else {
        if (this._state != null) {
          value = this._state[key];
        }
      }
      if (value === void 0 || value === 'null') {
        value = null;
      }
      this._options.afterGetState(key, value);
      return value;
    };

    Tour.prototype._showNextStep = function() {
      var promise, showNextStepHelper, step;
      step = this.getStep(this._current);
      showNextStepHelper = (function(_this) {
        return function(e) {
          return _this.showStep(step.next);
        };
      })(this);
      promise = this._makePromise(step.onNext != null ? step.onNext(this) : void 0);
      return this._callOnPromiseDone(promise, showNextStepHelper);
    };

    Tour.prototype._showPrevStep = function() {
      var promise, showPrevStepHelper, step;
      step = this.getStep(this._current);
      showPrevStepHelper = (function(_this) {
        return function(e) {
          return _this.showStep(step.prev);
        };
      })(this);
      promise = this._makePromise(step.onPrev != null ? step.onPrev(this) : void 0);
      return this._callOnPromiseDone(promise, showPrevStepHelper);
    };

    Tour.prototype._debug = function(text) {
      if (this._options.debug) {
        return window.console.log("Bootstrap Tour '" + this._options.name + "' | " + text);
      }
    };

    Tour.prototype._isRedirect = function(host, path, location) {
      var currentPath;
      if (host !== '') {
        if (this._isHostDifferent(host, location.href)) {
          return true;
        }
      }
      currentPath = [location.pathname, location.search, location.hash].join('');
      return (path != null) && path !== '' && (({}.toString.call(path) === '[object RegExp]' && !path.test(currentPath)) || ({}.toString.call(path) === '[object String]' && this._isPathDifferent(path, currentPath)));
    };

    Tour.prototype._isHostDifferent = function(host, currentURL) {
      return this._getProtocol(host) !== this._getProtocol(currentURL) || this._getHost(host) !== this._getHost(currentURL);
    };

    Tour.prototype._isPathDifferent = function(path, currentPath) {
      return this._getPath(path) !== this._getPath(currentPath) || !this._equal(this._getQuery(path), this._getQuery(currentPath)) || !this._equal(this._getHash(path), this._getHash(currentPath));
    };

    Tour.prototype._isJustPathHashDifferent = function(host, path, location) {
      var currentPath;
      if (host !== '') {
        if (this._isHostDifferent(host, location.href)) {
          return false;
        }
      }
      currentPath = [location.pathname, location.search, location.hash].join('');
      if ({}.toString.call(path) === '[object String]') {
        return this._getPath(path) === this._getPath(currentPath) && this._equal(this._getQuery(path), this._getQuery(currentPath)) && !this._equal(this._getHash(path), this._getHash(currentPath));
      }
      return false;
    };

    Tour.prototype._redirect = function(step, i, path) {
      if ($.isFunction(step.redirect)) {
        return step.redirect.call(this, path);
      } else if (step.redirect === true) {
        this._debug("Redirect to " + step.host + path);
        if (this._getState('redirect_to') === ("" + i)) {
          this._debug("Error redirection loop to " + path);
          this._removeState('redirect_to');
          if (step.onRedirectError != null) {
            return step.onRedirectError(this);
          }
        } else {
          this._setState('redirect_to', "" + i);
          return document.location.href = "" + step.host + path;
        }
      }
    };

    Tour.prototype._isOrphan = function(step) {
      return (step.element == null) || !$(step.element).length || $(step.element).is(':hidden') && ($(step.element)[0].namespaceURI !== 'http://www.w3.org/2000/svg');
    };

    Tour.prototype._isLast = function() {
      return this._current < this._options.steps.length - 1;
    };

    Tour.prototype._showPopover = function(step, i) {
      var $element, $tip, isOrphan, options, shouldAddSmart;
      $(".tour-" + this._options.name).remove();
      options = $.extend({}, this._options);
      isOrphan = this._isOrphan(step);
      step.template = this._template(step, i);
      if (isOrphan) {
        step.element = 'body';
        step.placement = 'top';
      }
      $element = $(step.element);
      $element.addClass("tour-" + this._options.name + "-element tour-" + this._options.name + "-" + i + "-element");
      if (step.options) {
        $.extend(options, step.options);
      }
      if (step.reflex && !isOrphan) {
        $(step.reflexElement).addClass('tour-step-element-reflex').off("" + (this._reflexEvent(step.reflex)) + ".tour-" + this._options.name).on("" + (this._reflexEvent(step.reflex)) + ".tour-" + this._options.name, (function(_this) {
          return function() {
            if (_this._isLast()) {
              return _this.next();
            } else {
              return _this.end();
            }
          };
        })(this));
      }
      shouldAddSmart = step.smartPlacement === true && step.placement.search(/auto/i) === -1;
      $element.popover({
        placement: shouldAddSmart ? "auto " + step.placement : step.placement,
        trigger: 'manual',
        title: step.title,
        content: step.content,
        html: true,
        animation: step.animation,
        container: step.container,
        template: step.template,
        selector: step.element
      }).popover('show');
      $tip = $element.data('bs.popover') ? $element.data('bs.popover').tip() : $element.data('popover').tip();
      $tip.attr('id', step.id);
      this._reposition($tip, step);
      if (isOrphan) {
        return this._center($tip);
      }
    };

    Tour.prototype._template = function(step, i) {
      var $end, $navigation, $next, $prev, $resume, $template, frozen, template;
      template = step.template;
      if (this._isOrphan(step) && {}.toString.call(step.orphan) !== '[object Boolean]') {
        template = step.orphan;
      }
      $template = $.isFunction(template) ? $(template(i, step)) : $(template);
      $navigation = $template.find('.popover-navigation');
      $prev = $navigation.find('[data-role="prev"]');
      $next = $navigation.find('[data-role="next"]');
      $end = $navigation.find('[data-role="end"]');
      $resume = $navigation.find('[data-role="pause-resume"]');
      frozen = step.isFrozen.call(this._options.frozenContext);
      if (this._isOrphan(step)) {
        $template.addClass('orphan');
      }
      $template.addClass("tour-" + this._options.name + " tour-" + this._options.name + "-" + i);
      if (step.reflex) {
        $template.addClass("tour-" + this._options.name + "-reflex");
      }
      if (step.prev < 0 || frozen) {
        $prev.addClass('disabled');
      }
      if (step.next < 0 || frozen) {
        $next.addClass('disabled');
      }
      if (frozen) {
        $end.addClass('disabled');
      }
      if (this._options.mustFinish && i + 1 < this._options.steps.length) {
        $end.addClass('hide');
      }
      if (!step.duration) {
        $resume.remove();
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

    Tour.prototype._reposition = function($tip, step) {
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
      if (step.placement === 'bottom' || step.placement === 'top') {
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
      offsetTop = $element.offset().top;
      windowHeight = $window.height();
      scrollTop = Math.max(0, offsetTop - (windowHeight / 2));
      this._debug("Scroll into view. ScrollTop: " + scrollTop + ". Element offset: " + offsetTop + ". Window height: " + windowHeight + ".");
      counter = 0;
      return $('body, html').stop(true, true).animate({
        scrollTop: Math.ceil(scrollTop)
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
      return $(window).on("resize.tour-" + this._options.name, function() {
        clearTimeout(timeout);
        return timeout = setTimeout(callback, 100);
      });
    };

    Tour.prototype._initMouseNavigation = function() {
      var _this;
      _this = this;
      return $(document).off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='prev']").off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='next']").off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='end']").off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='pause-resume']").on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='next']", (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.next();
        };
      })(this)).on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='prev']", (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.prev();
        };
      })(this)).on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='end']", (function(_this) {
        return function(e) {
          e.preventDefault();
          return _this.end();
        };
      })(this)).on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='pause-resume']", function(e) {
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

    Tour.prototype._initKeyboardNavigation = function() {
      if (!this._options.keyboard) {
        return;
      }
      return $(document).on("keyup.tour-" + this._options.name, (function(_this) {
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
              if (_this._current > 0) {
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

    Tour.prototype._makePromise = function(result) {
      if (result && $.isFunction(result.then)) {
        return result;
      } else {
        return null;
      }
    };

    Tour.prototype._callOnPromiseDone = function(promise, cb, arg) {
      if (promise) {
        return promise.then((function(_this) {
          return function(e) {
            return cb.call(_this, arg);
          };
        })(this));
      } else {
        return cb.call(this, arg);
      }
    };

    Tour.prototype._showBackdrop = function(step) {
      if (this.backdrop.backgroundShown) {
        return;
      }
      this.backdrop = $('<div>', {
        "class": 'tour-backdrop'
      });
      this.backdrop.backgroundShown = true;
      return $(step.backdropContainer).append(this.backdrop);
    };

    Tour.prototype._hideBackdrop = function() {
      this._hideOverlayElement();
      return this._hideBackground();
    };

    Tour.prototype._hideBackground = function() {
      if (this.backdrop) {
        this.backdrop.remove();
        this.backdrop.overlay = null;
        return this.backdrop.backgroundShown = false;
      }
    };

    Tour.prototype._showOverlayElement = function(step, force) {
      var $element, elementData;
      $element = $(step.element);
      if (!$element || $element.length === 0 || this.backdrop.overlayElementShown && !force) {
        return;
      }
      if (!this.backdrop.overlayElementShown) {
        this.backdrop.$element = $element.addClass('tour-step-backdrop');
        this.backdrop.$background = $('<div>', {
          "class": 'tour-step-background'
        });
        this.backdrop.$background.appendTo(step.backdropContainer);
        this.backdrop.overlayElementShown = true;
      }
      elementData = {
        width: $element.innerWidth(),
        height: $element.innerHeight(),
        offset: $element.offset()
      };
      if (step.backdropPadding) {
        elementData = this._applyBackdropPadding(step.backdropPadding, elementData);
      }
      return this.backdrop.$background.width(elementData.width).height(elementData.height).offset(elementData.offset);
    };

    Tour.prototype._hideOverlayElement = function() {
      if (!this.backdrop.overlayElementShown) {
        return;
      }
      this.backdrop.$element.removeClass('tour-step-backdrop');
      this.backdrop.$background.remove();
      this.backdrop.$element = null;
      this.backdrop.$background = null;
      return this.backdrop.overlayElementShown = false;
    };

    Tour.prototype._applyBackdropPadding = function(padding, data) {
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
      return data;
    };

    Tour.prototype._clearTimer = function() {
      window.clearTimeout(this._timer);
      this._timer = null;
      return this._duration = null;
    };

    Tour.prototype._getProtocol = function(url) {
      url = url.split('://');
      if (url.length > 1) {
        return url[0];
      } else {
        return 'http';
      }
    };

    Tour.prototype._getHost = function(url) {
      url = url.split('//');
      url = url.length > 1 ? url[1] : url[0];
      return url.split('/')[0];
    };

    Tour.prototype._getPath = function(path) {
      return path.replace(/\/?$/, '').split('?')[0].split('#')[0];
    };

    Tour.prototype._getQuery = function(path) {
      return this._getParams(path, '?');
    };

    Tour.prototype._getHash = function(path) {
      return this._getParams(path, '#');
    };

    Tour.prototype._getParams = function(path, start) {
      var param, params, paramsObject, _i, _len;
      params = path.split(start);
      if (params.length === 1) {
        return {};
      }
      params = params[1].split('&');
      paramsObject = {};
      for (_i = 0, _len = params.length; _i < _len; _i++) {
        param = params[_i];
        param = param.split('=');
        paramsObject[param[0]] = param[1] || '';
      }
      return paramsObject;
    };

    Tour.prototype._equal = function(obj1, obj2) {
      var k, v;
      if ({}.toString.call(obj1) === '[object Object]' && {}.toString.call(obj2) === '[object Object]') {
        for (k in obj1) {
          v = obj1[k];
          if (obj2[k] !== v) {
            return false;
          }
        }
        for (k in obj2) {
          v = obj2[k];
          if (obj1[k] !== v) {
            return false;
          }
        }
        return true;
      }
      return obj1 === obj2;
    };

    return Tour;

  })();
  return window.Tour = Tour;
})(jQuery, window);

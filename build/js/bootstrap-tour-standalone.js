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

/* ========================================================================
 * Bootstrap: tooltip.js v3.2.0
 * http://getbootstrap.com/javascript/#tooltip
 * Inspired by the original jQuery.tipsy by Jason Frame
 * ========================================================================
 * Copyright 2011-2014 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function ($) {
  'use strict';

  // TOOLTIP PUBLIC CLASS DEFINITION
  // ===============================

  var Tooltip = function (element, options) {
    this.type       =
    this.options    =
    this.enabled    =
    this.timeout    =
    this.hoverState =
    this.$element   = null

    this.init('tooltip', element, options)
  }

  Tooltip.VERSION  = '3.2.0'

  Tooltip.DEFAULTS = {
    animation: true,
    placement: 'top',
    selector: false,
    template: '<div class="tooltip" role="tooltip"><div class="tooltip-arrow"></div><div class="tooltip-inner"></div></div>',
    trigger: 'hover focus',
    title: '',
    delay: 0,
    html: false,
    container: false,
    viewport: {
      selector: 'body',
      padding: 0
    }
  }

  Tooltip.prototype.init = function (type, element, options) {
    this.enabled   = true
    this.type      = type
    this.$element  = $(element)
    this.options   = this.getOptions(options)
    this.$viewport = this.options.viewport && $(this.options.viewport.selector || this.options.viewport)

    var triggers = this.options.trigger.split(' ')

    for (var i = triggers.length; i--;) {
      var trigger = triggers[i]

      if (trigger == 'click') {
        this.$element.on('click.' + this.type, this.options.selector, $.proxy(this.toggle, this))
      } else if (trigger != 'manual') {
        var eventIn  = trigger == 'hover' ? 'mouseenter' : 'focusin'
        var eventOut = trigger == 'hover' ? 'mouseleave' : 'focusout'

        this.$element.on(eventIn  + '.' + this.type, this.options.selector, $.proxy(this.enter, this))
        this.$element.on(eventOut + '.' + this.type, this.options.selector, $.proxy(this.leave, this))
      }
    }

    this.options.selector ?
      (this._options = $.extend({}, this.options, { trigger: 'manual', selector: '' })) :
      this.fixTitle()
  }

  Tooltip.prototype.getDefaults = function () {
    return Tooltip.DEFAULTS
  }

  Tooltip.prototype.getOptions = function (options) {
    options = $.extend({}, this.getDefaults(), this.$element.data(), options)

    if (options.delay && typeof options.delay == 'number') {
      options.delay = {
        show: options.delay,
        hide: options.delay
      }
    }

    return options
  }

  Tooltip.prototype.getDelegateOptions = function () {
    var options  = {}
    var defaults = this.getDefaults()

    this._options && $.each(this._options, function (key, value) {
      if (defaults[key] != value) options[key] = value
    })

    return options
  }

  Tooltip.prototype.enter = function (obj) {
    var self = obj instanceof this.constructor ?
      obj : $(obj.currentTarget).data('bs.' + this.type)

    if (!self) {
      self = new this.constructor(obj.currentTarget, this.getDelegateOptions())
      $(obj.currentTarget).data('bs.' + this.type, self)
    }

    clearTimeout(self.timeout)

    self.hoverState = 'in'

    if (!self.options.delay || !self.options.delay.show) return self.show()

    self.timeout = setTimeout(function () {
      if (self.hoverState == 'in') self.show()
    }, self.options.delay.show)
  }

  Tooltip.prototype.leave = function (obj) {
    var self = obj instanceof this.constructor ?
      obj : $(obj.currentTarget).data('bs.' + this.type)

    if (!self) {
      self = new this.constructor(obj.currentTarget, this.getDelegateOptions())
      $(obj.currentTarget).data('bs.' + this.type, self)
    }

    clearTimeout(self.timeout)

    self.hoverState = 'out'

    if (!self.options.delay || !self.options.delay.hide) return self.hide()

    self.timeout = setTimeout(function () {
      if (self.hoverState == 'out') self.hide()
    }, self.options.delay.hide)
  }

  Tooltip.prototype.show = function () {
    var e = $.Event('show.bs.' + this.type)

    if (this.hasContent() && this.enabled) {
      this.$element.trigger(e)

      var inDom = $.contains(document.documentElement, this.$element[0])
      if (e.isDefaultPrevented() || !inDom) return
      var that = this

      var $tip = this.tip()

      var tipId = this.getUID(this.type)

      this.setContent()
      $tip.attr('id', tipId)
      this.$element.attr('aria-describedby', tipId)

      if (this.options.animation) $tip.addClass('fade')

      var placement = typeof this.options.placement == 'function' ?
        this.options.placement.call(this, $tip[0], this.$element[0]) :
        this.options.placement

      var autoToken = /\s?auto?\s?/i
      var autoPlace = autoToken.test(placement)
      if (autoPlace) placement = placement.replace(autoToken, '') || 'top'

      $tip
        .detach()
        .css({ top: 0, left: 0, display: 'block' })
        .addClass(placement)
        .data('bs.' + this.type, this)

      this.options.container ? $tip.appendTo(this.options.container) : $tip.insertAfter(this.$element)

      var pos          = this.getPosition()
      var actualWidth  = $tip[0].offsetWidth
      var actualHeight = $tip[0].offsetHeight

      if (autoPlace) {
        var orgPlacement = placement
        var $parent      = this.$element.parent()
        var parentDim    = this.getPosition($parent)

        placement = placement == 'bottom' && pos.top   + pos.height       + actualHeight - parentDim.scroll > parentDim.height ? 'top'    :
                    placement == 'top'    && pos.top   - parentDim.scroll - actualHeight < 0                                   ? 'bottom' :
                    placement == 'right'  && pos.right + actualWidth      > parentDim.width                                    ? 'left'   :
                    placement == 'left'   && pos.left  - actualWidth      < parentDim.left                                     ? 'right'  :
                    placement

        $tip
          .removeClass(orgPlacement)
          .addClass(placement)
      }

      var calculatedOffset = this.getCalculatedOffset(placement, pos, actualWidth, actualHeight)

      this.applyPlacement(calculatedOffset, placement)

      var complete = function () {
        that.$element.trigger('shown.bs.' + that.type)
        that.hoverState = null
      }

      $.support.transition && this.$tip.hasClass('fade') ?
        $tip
          .one('bsTransitionEnd', complete)
          .emulateTransitionEnd(150) :
        complete()
    }
  }

  Tooltip.prototype.applyPlacement = function (offset, placement) {
    var $tip   = this.tip()
    var width  = $tip[0].offsetWidth
    var height = $tip[0].offsetHeight

    // manually read margins because getBoundingClientRect includes difference
    var marginTop = parseInt($tip.css('margin-top'), 10)
    var marginLeft = parseInt($tip.css('margin-left'), 10)

    // we must check for NaN for ie 8/9
    if (isNaN(marginTop))  marginTop  = 0
    if (isNaN(marginLeft)) marginLeft = 0

    offset.top  = offset.top  + marginTop
    offset.left = offset.left + marginLeft

    // $.fn.offset doesn't round pixel values
    // so we use setOffset directly with our own function B-0
    $.offset.setOffset($tip[0], $.extend({
      using: function (props) {
        $tip.css({
          top: Math.round(props.top),
          left: Math.round(props.left)
        })
      }
    }, offset), 0)

    $tip.addClass('in')

    // check to see if placing tip in new offset caused the tip to resize itself
    var actualWidth  = $tip[0].offsetWidth
    var actualHeight = $tip[0].offsetHeight

    if (placement == 'top' && actualHeight != height) {
      offset.top = offset.top + height - actualHeight
    }

    var delta = this.getViewportAdjustedDelta(placement, offset, actualWidth, actualHeight)

    if (delta.left) offset.left += delta.left
    else offset.top += delta.top

    var arrowDelta          = delta.left ? delta.left * 2 - width + actualWidth : delta.top * 2 - height + actualHeight
    var arrowPosition       = delta.left ? 'left'        : 'top'
    var arrowOffsetPosition = delta.left ? 'offsetWidth' : 'offsetHeight'

    $tip.offset(offset)
    this.replaceArrow(arrowDelta, $tip[0][arrowOffsetPosition], arrowPosition)
  }

  Tooltip.prototype.replaceArrow = function (delta, dimension, position) {
    this.arrow().css(position, delta ? (50 * (1 - delta / dimension) + '%') : '')
  }

  Tooltip.prototype.setContent = function () {
    var $tip  = this.tip()
    var title = this.getTitle()

    $tip.find('.tooltip-inner')[this.options.html ? 'html' : 'text'](title)
    $tip.removeClass('fade in top bottom left right')
  }

  Tooltip.prototype.hide = function () {
    var that = this
    var $tip = this.tip()
    var e    = $.Event('hide.bs.' + this.type)

    this.$element.removeAttr('aria-describedby')

    function complete() {
      if (that.hoverState != 'in') $tip.detach()
      that.$element.trigger('hidden.bs.' + that.type)
    }

    this.$element.trigger(e)

    if (e.isDefaultPrevented()) return

    $tip.removeClass('in')

    $.support.transition && this.$tip.hasClass('fade') ?
      $tip
        .one('bsTransitionEnd', complete)
        .emulateTransitionEnd(150) :
      complete()

    this.hoverState = null

    return this
  }

  Tooltip.prototype.fixTitle = function () {
    var $e = this.$element
    if ($e.attr('title') || typeof ($e.attr('data-original-title')) != 'string') {
      $e.attr('data-original-title', $e.attr('title') || '').attr('title', '')
    }
  }

  Tooltip.prototype.hasContent = function () {
    return this.getTitle()
  }

  Tooltip.prototype.getPosition = function ($element) {
    $element   = $element || this.$element
    var el     = $element[0]
    var isBody = el.tagName == 'BODY'
    return $.extend({}, (typeof el.getBoundingClientRect == 'function') ? el.getBoundingClientRect() : null, {
      scroll: isBody ? document.documentElement.scrollTop || document.body.scrollTop : $element.scrollTop(),
      width:  isBody ? $(window).width()  : $element.outerWidth(),
      height: isBody ? $(window).height() : $element.outerHeight()
    }, isBody ? { top: 0, left: 0 } : $element.offset())
  }

  Tooltip.prototype.getCalculatedOffset = function (placement, pos, actualWidth, actualHeight) {
    return placement == 'bottom' ? { top: pos.top + pos.height,   left: pos.left + pos.width / 2 - actualWidth / 2  } :
           placement == 'top'    ? { top: pos.top - actualHeight, left: pos.left + pos.width / 2 - actualWidth / 2  } :
           placement == 'left'   ? { top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left - actualWidth } :
        /* placement == 'right' */ { top: pos.top + pos.height / 2 - actualHeight / 2, left: pos.left + pos.width   }

  }

  Tooltip.prototype.getViewportAdjustedDelta = function (placement, pos, actualWidth, actualHeight) {
    var delta = { top: 0, left: 0 }
    if (!this.$viewport) return delta

    var viewportPadding = this.options.viewport && this.options.viewport.padding || 0
    var viewportDimensions = this.getPosition(this.$viewport)

    if (/right|left/.test(placement)) {
      var topEdgeOffset    = pos.top - viewportPadding - viewportDimensions.scroll
      var bottomEdgeOffset = pos.top + viewportPadding - viewportDimensions.scroll + actualHeight
      if (topEdgeOffset < viewportDimensions.top) { // top overflow
        delta.top = viewportDimensions.top - topEdgeOffset
      } else if (bottomEdgeOffset > viewportDimensions.top + viewportDimensions.height) { // bottom overflow
        delta.top = viewportDimensions.top + viewportDimensions.height - bottomEdgeOffset
      }
    } else {
      var leftEdgeOffset  = pos.left - viewportPadding
      var rightEdgeOffset = pos.left + viewportPadding + actualWidth
      if (leftEdgeOffset < viewportDimensions.left) { // left overflow
        delta.left = viewportDimensions.left - leftEdgeOffset
      } else if (rightEdgeOffset > viewportDimensions.width) { // right overflow
        delta.left = viewportDimensions.left + viewportDimensions.width - rightEdgeOffset
      }
    }

    return delta
  }

  Tooltip.prototype.getTitle = function () {
    var title
    var $e = this.$element
    var o  = this.options

    title = $e.attr('data-original-title')
      || (typeof o.title == 'function' ? o.title.call($e[0]) :  o.title)

    return title
  }

  Tooltip.prototype.getUID = function (prefix) {
    do prefix += ~~(Math.random() * 1000000)
    while (document.getElementById(prefix))
    return prefix
  }

  Tooltip.prototype.tip = function () {
    return (this.$tip = this.$tip || $(this.options.template))
  }

  Tooltip.prototype.arrow = function () {
    return (this.$arrow = this.$arrow || this.tip().find('.tooltip-arrow'))
  }

  Tooltip.prototype.validate = function () {
    if (!this.$element[0].parentNode) {
      this.hide()
      this.$element = null
      this.options  = null
    }
  }

  Tooltip.prototype.enable = function () {
    this.enabled = true
  }

  Tooltip.prototype.disable = function () {
    this.enabled = false
  }

  Tooltip.prototype.toggleEnabled = function () {
    this.enabled = !this.enabled
  }

  Tooltip.prototype.toggle = function (e) {
    var self = this
    if (e) {
      self = $(e.currentTarget).data('bs.' + this.type)
      if (!self) {
        self = new this.constructor(e.currentTarget, this.getDelegateOptions())
        $(e.currentTarget).data('bs.' + this.type, self)
      }
    }

    self.tip().hasClass('in') ? self.leave(self) : self.enter(self)
  }

  Tooltip.prototype.destroy = function () {
    clearTimeout(this.timeout)
    this.hide().$element.off('.' + this.type).removeData('bs.' + this.type)
  }


  // TOOLTIP PLUGIN DEFINITION
  // =========================

  function Plugin(option) {
    return this.each(function () {
      var $this   = $(this)
      var data    = $this.data('bs.tooltip')
      var options = typeof option == 'object' && option

      if (!data && option == 'destroy') return
      if (!data) $this.data('bs.tooltip', (data = new Tooltip(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = $.fn.tooltip

  $.fn.tooltip             = Plugin
  $.fn.tooltip.Constructor = Tooltip


  // TOOLTIP NO CONFLICT
  // ===================

  $.fn.tooltip.noConflict = function () {
    $.fn.tooltip = old
    return this
  }

}(jQuery);

/* ========================================================================
 * Bootstrap: popover.js v3.2.0
 * http://getbootstrap.com/javascript/#popovers
 * ========================================================================
 * Copyright 2011-2014 Twitter, Inc.
 * Licensed under MIT (https://github.com/twbs/bootstrap/blob/master/LICENSE)
 * ======================================================================== */


+function ($) {
  'use strict';

  // POPOVER PUBLIC CLASS DEFINITION
  // ===============================

  var Popover = function (element, options) {
    this.init('popover', element, options)
  }

  if (!$.fn.tooltip) throw new Error('Popover requires tooltip.js')

  Popover.VERSION  = '3.2.0'

  Popover.DEFAULTS = $.extend({}, $.fn.tooltip.Constructor.DEFAULTS, {
    placement: 'right',
    trigger: 'click',
    content: '',
    template: '<div class="popover" role="tooltip"><div class="arrow"></div><h3 class="popover-title"></h3><div class="popover-content"></div></div>'
  })


  // NOTE: POPOVER EXTENDS tooltip.js
  // ================================

  Popover.prototype = $.extend({}, $.fn.tooltip.Constructor.prototype)

  Popover.prototype.constructor = Popover

  Popover.prototype.getDefaults = function () {
    return Popover.DEFAULTS
  }

  Popover.prototype.setContent = function () {
    var $tip    = this.tip()
    var title   = this.getTitle()
    var content = this.getContent()

    $tip.find('.popover-title')[this.options.html ? 'html' : 'text'](title)
    $tip.find('.popover-content').empty()[ // we use append for html objects to maintain js events
      this.options.html ? (typeof content == 'string' ? 'html' : 'append') : 'text'
    ](content)

    $tip.removeClass('fade top bottom left right in')

    // IE8 doesn't accept hiding via the `:empty` pseudo selector, we have to do
    // this manually by checking the contents.
    if (!$tip.find('.popover-title').html()) $tip.find('.popover-title').hide()
  }

  Popover.prototype.hasContent = function () {
    return this.getTitle() || this.getContent()
  }

  Popover.prototype.getContent = function () {
    var $e = this.$element
    var o  = this.options

    return $e.attr('data-content')
      || (typeof o.content == 'function' ?
            o.content.call($e[0]) :
            o.content)
  }

  Popover.prototype.arrow = function () {
    return (this.$arrow = this.$arrow || this.tip().find('.arrow'))
  }

  Popover.prototype.tip = function () {
    if (!this.$tip) this.$tip = $(this.options.template)
    return this.$tip
  }


  // POPOVER PLUGIN DEFINITION
  // =========================

  function Plugin(option) {
    return this.each(function () {
      var $this   = $(this)
      var data    = $this.data('bs.popover')
      var options = typeof option == 'object' && option

      if (!data && option == 'destroy') return
      if (!data) $this.data('bs.popover', (data = new Popover(this, options)))
      if (typeof option == 'string') data[option]()
    })
  }

  var old = $.fn.popover

  $.fn.popover             = Plugin
  $.fn.popover.Constructor = Popover


  // POPOVER NO CONFLICT
  // ===================

  $.fn.popover.noConflict = function () {
    $.fn.popover = old
    return this
  }

}(jQuery);

(function($, window) {
  'use strict';
  var Step, Tour;
  Tour = (function() {
    function Tour(options) {
      if (options == null) {
        options = {};
      }
      this.options = $.extend(Tour.defaults, options);
      this.steps = [];
      this.force = false;
      this.inited = false;
      this.backdrop = {
        overlay: null,
        $element: null,
        $background: null,
        backgroundShown: false,
        overlayElementShown: false
      };
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
      if (!this.steps[i]) {
        return false;
      }
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
      if (this.current) {
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
        this._onPromiseDone(this._promise(this.options.onStart != null ? this.options.onStart(this) : void 0), this.showStep, 0);
      }
      return this;
    };

    Tour.prototype.next = function() {
      return this._onPromiseDone(this.hideStep(this.current), this._showNextStep);
    };

    Tour.prototype.prev = function() {
      return this._onPromiseDone(this.hideStep(this.current), this._showPrevStep);
    };

    Tour.prototype.goTo = function(i) {
      return this._onPromiseDone(this.hideStep(this.current), this.showStep, i);
    };

    Tour.prototype.end = function() {
      return this._onPromiseDone(this.hideStep(this.current), (function(_this) {
        return function(e) {
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
      })(this));
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
      if (!(step && step.duration)) {
        return this;
      }
      this._paused = true;
      this._duration -= new Date().getTime() - this._start;
      window.clearTimeout(this._timer);
      this._debug("Paused/Stopped step " + (this.current + 1) + " timer (" + this._duration + " remaining).");
      if (step.onPause != null) {
        return step.onPause(this, this._duration);
      }
    };

    Tour.prototype.resume = function() {
      var step;
      step = this.step(this.current);
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
      this._debug("Started step " + (this.current + 1) + " timer with duration " + this._duration);
      if ((step.onResume != null) && this._duration !== step.duration) {
        return step.onResume(this, this._duration);
      }
    };

    Tour.prototype.hideStep = function(i) {
      var promise, step;
      step = this.step(i);
      if (!step) {
        return;
      }
      this._clearTimer();
      promise = this._promise(step.onHide != null ? step.onHide(this, i) : void 0);
      this._onPromiseDone(promise, (function(_this) {
        return function(e) {
          var $element;
          $element = $(step.element);
          if (!($element.data('bs.popover') || $element.data('popover'))) {
            $element = $('body');
          }
          $element.popover('destroy').removeClass("tour-" + _this.options.name + "-element tour-" + _this.options.name + "-" + i + "-element");
          if (step.reflex) {
            $element.removeClass('tour-step-element-reflex').off("" + (_this._reflexEvent(step.reflex)) + ".tour-" + _this.options.name);
          }
          if (step.backdrop) {
            _this._hideBackdrop();
          }
          if (step.onHidden != null) {
            return step.onHidden(_this);
          }
        };
      })(this));
      return promise;
    };

    Tour.prototype.showStep = function(i) {
      var promise, showStepHelper, skipToPrevious, step;
      if (this.ended()) {
        this._debug('Tour ended, showStep prevented.');
        return this;
      }
      step = this.step(i);
      if (!step) {
        return;
      }
      skipToPrevious = i < this.current;
      promise = this._promise(step.onShow != null ? step.onShow(this, i) : void 0);
      showStepHelper = (function(_this) {
        return function(e) {
          var current_path, path;
          _this.currentStep(i);
          path = (function() {
            switch ({}.toString.call(step.path)) {
              case '[object Function]':
                return step.path();
              case '[object String]':
                return this.options.basePath + step.path;
              default:
                return step.path;
            }
          }).call(_this);
          current_path = [document.location.pathname, document.location.hash].join('');
          if (_this._isRedirect(path, current_path)) {
            _this._redirect(step, path);
            return;
          }
          if (_this._isOrphan(step)) {
            if (!step.orphan) {
              _this._debug("Skip the orphan step " + (_this.current + 1) + ".\nOrphan option is false and the element does not exist or is hidden.");
              if (skipToPrevious) {
                _this._showPrevStep();
              } else {
                _this._showNextStep();
              }
              return;
            }
            _this._debug("Show the orphan step " + (_this.current + 1) + ". Orphans option is true.");
          }
          if (step.backdrop) {
            _this._showBackdrop(!_this._isOrphan(step) ? step.element : void 0);
          }
          _this._scrollIntoView(step.element, function() {
            if (_this.currentStep() !== i) {
              return;
            }
            if ((step.element != null) && step.backdrop) {
              _this._showOverlayElement(step);
            }
            _this._showPopover(step, i);
            if (step.onShown != null) {
              step.onShown(_this);
            }
            return _this._debug("Step " + (_this.current + 1) + " of " + _this.steps.length);
          });
          if (step.duration) {
            return _this.resume();
          }
        };
      })(this);
      if (step.delay) {
        this._debug("Wait " + step.delay + " milliseconds to show the step " + (this.current + 1));
        window.setTimeout((function(_this) {
          return function() {
            return _this._onPromiseDone(promise, showStepHelper);
          };
        })(this), step.delay);
      } else {
        this._onPromiseDone(promise, showStepHelper);
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
      console.log(this.options);
      this.options.afterGetState(key, value);
      return value;
    };

    Tour.prototype._showNextStep = function() {
      var step;
      step = this.step(this.current);
      return this._onPromiseDone(this._promise(step.onNext != null ? step.onNext(this) : void 0), (function(_this) {
        return function(e) {
          return _this.showStep(_this.current + 1);
        };
      })(this));
    };

    Tour.prototype._showPrevStep = function() {
      var step;
      step = this.step(this.current);
      return this._onPromiseDone(this._promise(step.onPrev != null ? step.onPrev(this) : void 0), (function(_this) {
        return function(e) {
          return _this.showStep(_this.current - 1);
        };
      })(this));
    };

    Tour.prototype._debug = function(text) {
      if (this.options.debug) {
        return window.console.log("Bootstrap Tour '" + this.options.name + "' | " + text);
      }
    };

    Tour.prototype._isRedirect = function(path, currentPath) {
      return (path != null) && path !== '' && (({}.toString.call(path) === '[object RegExp]' && !path.test(currentPath)) || ({}.toString.call(path) === '[object String]' && path.replace(/\?.*$/, '').replace(/\/?$/, '') !== currentPath.replace(/\/?$/, '')));
    };

    Tour.prototype._redirect = function(step, path) {
      if ($.isFunction(step.redirect)) {
        return step.redirect.call(this, path);
      } else if (step.redirect === true) {
        this._debug("Redirect to " + path);
        return document.location.href = path;
      }
    };

    Tour.prototype._isOrphan = function(step) {
      return (step.element == null) || !$(step.element).length || $(step.element).is(':hidden') && ($(step.element)[0].namespaceURI !== 'http://www.w3.org/2000/svg');
    };

    Tour.prototype._isLast = function() {
      return this.current < this.steps.length - 1;
    };

    Tour.prototype._showPopover = function(step, i) {
      var $element, $tip, isOrphan, options;
      $(".tour-" + this.options.name).remove();
      options = $.extend({}, this.options);
      isOrphan = this._isOrphan(step);
      step.template = this._template(step, i);
      if (isOrphan) {
        step.element = 'body';
        step.placement = 'top';
      }
      $element = $(step.element);
      $element.addClass("tour-" + this.options.name + "-element tour-" + this.options.name + "-" + i + "-element");
      if (step.options) {
        $.extend(options, step.options);
      }
      if (step.reflex && !isOrphan) {
        $element.addClass('tour-step-element-reflex');
        $element.off("" + (this._reflexEvent(step.reflex)) + ".tour-" + this.options.name);
        $element.on("" + (this._reflexEvent(step.reflex)) + ".tour-" + this.options.name, (function(_this) {
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
        placement: step.placement,
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
      $tip.attr('id', "tour-step-" + i + "-tooltip");
      this._reposition($tip, step);
      if (this._isOrphan(step)) {
        return this._center($tip);
      }
    };

    Tour.prototype._template = function(step, i) {
      var $navigation, $next, $prev, $template;
      $template = $.isFunction(step.template) ? $(step.template(i, step)) : $(step.template);
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
      if (!step.duration) {
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

    Tour.prototype._promise = function(result) {
      if (result && $.isFunction(result.then)) {
        return result;
      } else {
        return null;
      }
    };

    Tour.prototype._onPromiseDone = function(promise, fn, parameters) {
      if (promise) {
        return promise.then((function(_this) {
          return function(e) {
            return fn.call(_this, parameters);
          };
        })(this));
      } else {
        return fn.call(this, parameters);
      }
    };

    Tour.prototype._showBackdrop = function(element) {
      if (this.backdrop.backgroundShown) {
        return;
      }
      this.backdrop = $('<div>', {
        "class": 'tour-backdrop'
      });
      this.backdrop.backgroundShown = true;
      return $('body').append(this.backdrop);
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

    Tour.prototype._showOverlayElement = function(step) {
      var $element, elementData;
      $element = $(step.element);
      if (!$element || $element.length === 0 || this.backdrop.overlayElementShown) {
        return;
      }
      this.backdrop.overlayElementShown = true;
      this.backdrop.$element = $element.addClass('tour-step-backdrop');
      this.backdrop.$background = $('<div>', {
        "class": 'tour-step-background'
      });
      elementData = {
        width: $element.innerWidth(),
        height: $element.innerHeight(),
        offset: $element.offset()
      };
      this.backdrop.$background.appendTo('body');
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

    return Tour;

  })();
  Step = (function() {
    function Step(options) {
      if (options == null) {
        options = {};
      }
      this.options = $.extend(TourStep.defaults, options);
    }

    return Step;

  })();
  window.Tour = Tour;
  window.TourStep = Step;
  window.Tour.defaults = {
    name: 'tour',
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

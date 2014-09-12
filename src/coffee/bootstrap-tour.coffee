do ($ = window.jQuery, window) ->
  'use strict'

  class Tour
    constructor: (options = {}) ->
      @options = $.extend {}, Tour.defaults, options
      @steps = []
      @force = false
      @inited = false
      @$backdrop = null
      @$backdropOverlay = null
      @addSteps @options.steps if @options.steps.length
      @

    # Add multiple steps
    addSteps: (steps) ->
      for step in steps
        @addStep step
      @

    # Add a new step
    addStep: (step) ->
      @steps.push new TourStep step
      @

    # Get a step by its index
    step: (i) ->
      @steps[i]

    # get or set the current step
    currentStep: (value) ->
      return @current if typeof value is 'undefined'

      @current = value
      @_setState 'current_step', value

    # Setup event bindings and continue a tour that has already started
    init: (force) ->
      @force = force
      current = @_getState 'current_step'
      @current = if current is null then current else parseInt current, 10

      if @ended()
        @_debug 'Tour ended, init prevented.'
        return @

      @_keyboard @options.keyboard
      @_mouse()

      # Reshow popover on window resize using debounced resize
      @_onResize => @showStep @current

      # Continue a tour that had started on a previous page load
      @showStep @current if @current?

      @inited = true
      @

    # Start tour from current step
    start: (force = false) ->
      @init force unless @inited # Backward compatibility

      if @current is null
        @_onPromiseDone @_promise(@options.onStart(@) if @options.onStart?), @showStep, 0
      @

    # Hide current step and show next step
    next: ->
      @_onPromiseDone @hideStep(@current), @_showNextStep

    # Hide current step and show prev step
    prev: ->
      @_onPromiseDone @hideStep(@current), @_showPrevStep

    goTo: (i) ->
      @_onPromiseDone @hideStep(@current), @showStep, i

    # End tour
    end: ->
      @_onPromiseDone @hideStep(@current), (e) =>
        $(document).off "click.tour-#{@options.name}"
        $(document).off "keyup.tour-#{@options.name}"
        $(window).off "resize.tour-#{@options.name}"
        @_setState('end', 'yes')
        @inited = false
        @force = false

        @_clearTimer()

        @options.onEnd(@) if @options.onEnd?

    # Verify if tour is enabled
    ended: ->
      not @force and not not @_getState 'end'

    # Restart tour
    restart: ->
      @_removeState 'current_step'
      @_removeState 'end'
      @start()

    # Pause step timer
    pause: ->
      step = @step @current
      return @ if not step or not step.options.duration

      @_paused = true
      @_duration -= new Date().getTime() - @_start
      window.clearTimeout @_timer

      @_debug "Paused/Stopped step #{@current + 1} timer (#{@_duration} remaining)."

      step.options.onPause @, @_duration if step.options.onPause?

    # Resume step timer
    resume: ->
      step = @step @current
      return @ if not step or not step.options.duration

      @_paused = false
      @_start = new Date().getTime()
      @_duration = @_duration or step.options.duration
      @_timer = window.setTimeout =>
        if @_isLast() then @next() else @end()
      , @_duration

      @_debug "Started step #{@current + 1} timer with duration #{@_duration}"

      step.options.onResume @, @_duration if step.options.onResume? and @_duration isnt step.options.duration

    # Hide the specified step
    hideStep: (i) ->
      step = @step i
      return unless step

      options = step.options
      @_clearTimer()

      # If onHide returns a promise, let's wait until it's done to execute
      promise = @_promise(options.onHide @, i if options.onHide?)

      @_hideBackdrop() if options.backdrop

      @_onPromiseDone promise, (e) =>
        $element = $ options.element
        $element = $('body') unless $element.data('bs.popover') or $element.data 'popover'
        $element
        .popover('destroy')
        .removeClass "tour-#{@options.name}-element tour-#{@options.name}-#{i}-element"
        if options.reflex
          $element
          .removeClass('tour-step-element-reflex')
          .off "#{@_reflexEvent(options.reflex)}.tour-#{@options.name}"

        @_hideStepBackdrop options.element if options.backdrop

        options.onHidden @ if options.onHidden?

      promise

    # Show the specified step
    showStep: (i) ->
      if @ended()
        @_debug 'Tour ended, showStep prevented.'
        return @

      step = @step i
      return unless step

      options = step.options
      skipToPrevious = i < @current

      # If onShow returns a promise, let's wait until it's done to execute
      promise = @_promise(options.onShow @, i if options.onShow?)

      showStepHelper = (e) =>
        @currentStep i

        # Support string or function for path
        options.path = switch ({}).toString.call options.path
          when '[object Function]' then options.path()
          when '[object String]' then @options.basePath + options.path
          else options.path

        # Redirect to step path if not already there
        if @_isRedirect options.path, [document.location.pathname, document.location.hash].join('')
          @_redirect options.redirect, options.path
          return

        # Skip if step is orphan and orphan options is false
        if @_isOrphan options.element
          if not options.orphan
            @_debug """Skip the orphan step #{@current + 1}.
            Orphan option is false and the element does not exist or is hidden."""
            @[if skipToPrevious then '_showPrevStep' else '_showNextStep']()
            return

          @_debug "Show the orphan step #{@current + 1}. Orphans option is true."

        # Show backdrop
        @_showBackdrop(options.element unless @_isOrphan options.element) if options.backdrop

        # Scroll into view and show popover
        @_scrollIntoView options.element, =>
          return if @currentStep() isnt i

          @_showStepBackdrop step if options.element? and options.backdrop

          @_showPopover step, i
          options.onShown @ if options.onShown?
          @_debug "Step #{@current + 1} of #{@steps.length}"

        # Play step timer
        @resume() if options.duration

      if options.delay
        @_debug "Wait #{options.delay} milliseconds to show the step #{@current + 1}"
        window.setTimeout =>
          @_onPromiseDone promise, showStepHelper
        , options.delay
      else
        @_onPromiseDone promise, showStepHelper

      promise

    # Set a state in storage
    _setState: (key, value) ->
      if @options.storage
        keyName = "#{@options.name}_#{key}"
        try @options.storage.setItem keyName, value
        catch e
          if e.code is DOMException.QUOTA_EXCEEDED_ERR
            @debug 'LocalStorage quota exceeded. State storage failed.'
        @options.afterSetState keyName, value
      else
        @_state ?= {}
        @_state[key] = value

    # Remove the current state from the storage layer
    _removeState: (key) ->
      if @options.storage
        keyName = "#{@options.name}_#{key}"
        @options.storage.removeItem keyName
        @options.afterRemoveState keyName
      else
        delete @_state[key] if @_state?

    # Get the current state from the storage layer
    _getState: (key) ->
      if @options.storage
        keyName = "#{@options.name}_#{key}"
        value = @options.storage.getItem keyName
      else
        value = @_state[key] if @_state?

      value = null if value is undefined or value is 'null'

      @options.afterGetState key, value
      return value

    # Show next step
    _showNextStep: ->
      step = @step @current
      options = step.options

      @_onPromiseDone @_promise(options.onNext @ if options.onNext?), (e) => @showStep @current + 1

    # Show prev step
    _showPrevStep: ->
      step = @step @current
      options = step.options

      @_onPromiseDone @_promise(options.onPrev @ if options.onPrev?), (e) => @showStep @current - 1

    # Print message in console
    _debug: (text) ->
      window.console.log "Bootstrap Tour '#{@options.name}' | #{text}" if @options.debug

    # Check if step path equals current document path
    _isRedirect: (path, currentPath) ->
      path? and path isnt '' and (
        (({}).toString.call(path) is '[object RegExp]' and not path.test currentPath) or
        (({}).toString.call(path) is '[object String]' and
          path.replace(/\?.*$/, '').replace(/\/?$/, '') isnt currentPath.replace(/\/?$/, ''))
      )

    # Execute the redirect
    _redirect: (redirect, path) ->
      if $.isFunction redirect
        redirect.call this, path
      else if redirect is true
        @_debug "Redirect to #{path}"
        document.location.href = path

    _isOrphan: (element) ->
      return false if element?

      $element = $(element)

      # Do not check for is(':hidden') on svg elements. jQuery does not work properly on svg.
      not $element.length or
      $element.is(':hidden') and
      $element[0].namespaceURI isnt 'http://www.w3.org/2000/svg'

    _isLast: ->
      @current < @steps.length - 1

    # Show step popover
    _showPopover: (step, i) ->
      options = step.options

      # Remove previously existing tour popovers. This prevents displaying of
      # multiple inactive popovers when user navigates the tour too quickly.
      $(".tour-#{@options.name}").remove()

      # set up step before popover creation
      isOrphan = @_isOrphan options.element
      options.template = @_template step, i

      if isOrphan
        options.element = 'body'
        options.placement = 'top'

      # add classes to popover element
      $element = $ options.element
      $element.addClass "tour-#{@options.name}-element tour-#{@options.name}-#{i}-element"

      # add reflex handlers
      if options.reflex and not isOrphan
        $element.addClass('tour-step-element-reflex')
        $element.off("#{@_reflexEvent(options.reflex)}.tour-#{@options.name}")
        $element.on "#{@_reflexEvent(options.reflex)}.tour-#{@options.name}", =>
          if @_isLast() then @next() else @end()

      $element
      .popover(
        placement: options.placement
        trigger: 'manual'
        title: options.title
        content: options.content
        html: true
        animation: options.animation
        container: options.container
        template: options.template
        selector: options.element
      )
      .popover 'show'

      # adjust tip
      $tip = if $element.data 'bs.popover' then $element.data('bs.popover').tip() else $element.data('popover').tip()
      $tip.attr 'id', "tour-step-#{i}-tooltip"
      @_reposition $tip, options.placement
      @_center $tip if isOrphan

    # Get popover template
    _template: (step, i) ->
      options = step.options

      $template = if $.isFunction options.template then $(options.template i, step) else $(options.template)
      $navigation = $template.find '.popover-navigation'
      $prev = $navigation.find '[data-role="prev"]'
      $next = $navigation.find '[data-role="next"]'

      $template.addClass 'orphan' if @_isOrphan options.element
      $template.addClass "tour-#{@options.name} tour-#{@options.name}-#{i}"
      $navigation.find('[data-role="prev"]').addClass('disabled') if i is 0
      $navigation.find('[data-role="next"]').addClass('disabled') if i is @steps.length - 1
      $navigation.find('[data-role="pause-resume"]').remove() unless options.duration
      $template.clone().wrap('<div>').parent().html()

    _reflexEvent: (reflex) ->
      if ({}).toString.call(reflex) is '[object Boolean]' then 'click' else reflex

    # Prevent popover from crossing over the edge of the window
    _reposition: ($tip, placement) ->
      offsetWidth = $tip[0].offsetWidth
      offsetHeight = $tip[0].offsetHeight

      tipOffset = $tip.offset()
      originalLeft = tipOffset.left
      originalTop = tipOffset.top
      offsetBottom = $(document).outerHeight() - tipOffset.top - $tip.outerHeight()
      tipOffset.top = tipOffset.top + offsetBottom if offsetBottom < 0
      offsetRight = $('html').outerWidth() - tipOffset.left - $tip.outerWidth()
      tipOffset.left = tipOffset.left + offsetRight if offsetRight < 0

      tipOffset.top = 0 if tipOffset.top < 0
      tipOffset.left = 0 if tipOffset.left < 0

      $tip.offset(tipOffset)

      # Reposition the arrow
      if placement is 'bottom' or placement is 'top'
        if originalLeft isnt tipOffset.left
          @_replaceArrow $tip, (tipOffset.left - originalLeft) * 2, offsetWidth, 'left'
      else
        if originalTop isnt tipOffset.top
          @_replaceArrow $tip, (tipOffset.top - originalTop) * 2, offsetHeight, 'top'

    # Center popover in the page
    _center: ($tip) ->
      $tip.css('top', $(window).outerHeight() / 2 - $tip.outerHeight() / 2)

    # Copy pasted from bootstrap-tooltip.js with some alterations
    _replaceArrow: ($tip, delta, dimension, position)->
      $tip.find('.arrow').css position, if delta then 50 * (1 - delta / dimension) + '%' else ''

    # Scroll to the popup if it is not in the viewport
    _scrollIntoView: (element, callback) ->
      $element = $ element

      return callback() unless $element.length

      $window = $ window
      windowHeight = $window.height()
      offsetTop = $element.offset().top
      scrollTop = Math.ceil Math.max 0, offsetTop - (windowHeight / 2)
      counter = 0

      @_debug "Scroll into view. ScrollTop: #{scrollTop}. Element offset: #{offsetTop}. Window height: #{windowHeight}."

      $('body, html')
      .stop(true, true)
      .animate scrollTop: scrollTop, =>
        if ++counter is 2
          callback()
          @_debug """Scroll into view.
          Animation end element offset: #{$element.offset().top}.
          Window height: #{$window.height()}."""

    # Debounced window resize
    _onResize: (callback, timeout) ->
      $(window).on "resize.tour-#{@options.name}", ->
        clearTimeout(timeout)
        timeout = setTimeout(callback, 100)

    # Event bindings for mouse navigation
    _mouse: ->
      _this = @

      # Go to next step after click on element with attribute 'data-role=next'
      # Go to previous step after click on element with attribute 'data-role=prev'
      # End tour after click on element with attribute 'data-role=end'
      # Pause/resume tour after click on element with attribute 'data-role=pause-resume'
      $(document)
      .off("click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='prev']")
      .off("click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='next']")
      .off("click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='end']")
      .off("click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='pause-resume']")
      .on "click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='next']", (e) =>
        e.preventDefault()
        @next()
      .on "click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='prev']", (e) =>
        e.preventDefault()
        @prev()
      .on "click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='end']", (e) =>
        e.preventDefault()
        @end()
      .on "click.tour-#{@options.name}", ".popover.tour-#{@options.name} *[data-role='pause-resume']", (e) ->
        e.preventDefault()
        $this = $ @

        $this.text if _this._paused then $this.data 'pause-text' else $this.data 'resume-text'
        if _this._paused then _this.resume() else _this.pause()

    # Keyboard navigation
    _keyboard: ->
      return @options.keyboard if typeof value is 'undefined'

      $(document)
      .off("keyup.tour-#{@options.name}")
      .on "keyup.tour-#{@options.name}", (e) =>
        return unless e.which

        switch e.which
          when 39
            e.preventDefault()
            if @_isLast() then @next() else @end()
          when 37
            e.preventDefault()
            @prev() if @current > 0
          when 27
            e.preventDefault()
            @end()

    # Checks if the result of a callback is a promise
    _promise: (result) ->
      if result and $.isFunction(result.then) then result else null

    _onPromiseDone: (promise, fn, parameters) ->
      if promise
        promise.then (e) =>
          fn.call(@, parameters)
      else
        fn.call(@, parameters)

    _showBackdrop: ->
      return if @$backdrop and @$backdrop.length

      @$backdrop = $('<div>', class: 'tour-backdrop').appendTo 'body'

    _showStepBackdrop: (step) ->
      options = step.options
      $element = $ options.element

      return if not $element.length or (@$backdropOverlay and @$backdropOverlay.length)

      $element.addClass 'tour-backdrop-step'
      @$backdropOverlay = $('<div>', do ->
        data =
          class: 'tour-backdrop-step-overlay'
          width: $element.innerWidth()
          height: $element.innerHeight()
          offset: $element.offset()
        padding = options.backdropPadding

        if padding
          if typeof padding is 'object'
            padding.top ?= 0
            padding.right ?= 0
            padding.bottom ?= 0
            padding.left ?= 0

            data.offset.top = data.offset.top - padding.top
            data.offset.left = data.offset.left - padding.left
            data.width = data.width + padding.left + padding.right
            data.height = data.height + padding.top + padding.bottom
          else
            data.offset.top = data.offset.top - padding
            data.offset.left = data.offset.left - padding
            data.width = data.width + (padding * 2)
            data.height = data.height + (padding * 2)
        data
      ).appendTo 'body'

    _hideBackdrop: ->
      if @$backdrop and @$backdrop.length
        @$backdrop.remove()

    _hideStepBackdrop: (element) ->
      $element = $(element)

      return if not $element.length or (not @$backdropOverlay or not @$backdropOverlay.length)

      $element.removeClass 'tour-backdrop-step'
      @$backdropOverlay.remove()

    _clearTimer: ->
      window.clearTimeout @_timer
      @_timer = null
      @_duration = null


  # Tour Step
  class TourStep
    constructor: (options = {}) ->
      @options = $.extend {}, TourStep.defaults, options

  window.Tour = Tour
  window.TourStep = TourStep

  window.Tour.defaults =
    name: 'tour'
    steps: []
    basePath: ''
    storage: do ->
      # localStorage may be unavailable due to security settings
      try
        storage = window.localStorage
      catch
        storage = false
      storage
    debug: false
    afterSetState: (key, value) ->
    afterGetState: (key, value) ->
    afterRemoveState: (key) ->
    onStart: (tour) ->
    onEnd: (tour) ->

  window.TourStep.defaults =
    path: ''
    placement: 'right'
    title: ''
    content: '<p></p>' # no empty as default, otherwise popover won't show up
    animation: true
    container: 'body'
    keyboard: true
    backdrop: false
    backdropPadding: 0
    redirect: true
    orphan: false
    duration: false
    delay: false
    template: '<div class="popover" role="tooltip">
      <div class="arrow"></div>
      <h3 class="popover-title"></h3>
      <div class="popover-content"></div>
      <div class="popover-navigation">
        <div class="btn-group">
          <button class="btn btn-sm btn-default" data-role="prev">&laquo; Prev</button>
          <button class="btn btn-sm btn-default" data-role="next">Next &raquo;</button>
          <button class="btn btn-sm btn-default"
                  data-role="pause-resume"
                  data-pause-text="Pause"
                  data-resume-text="Resume">Pause</button>
        </div>
        <button class="btn btn-sm btn-default" data-role="end">End tour</button>
      </div>
    </div>'
    onShow: (tour) ->
    onShown: (tour) ->
    onHide: (tour) ->
    onHidden: (tour) ->
    onNext: (tour) ->
    onPrev: (tour) ->
    onPause: (tour, duration) ->
    onResume: (tour, duration) ->

(($, window) ->
  document = window.document

  class Tour
    constructor: (options) ->
      try
        storage = window.localStorage
      catch
        # localStorage may be unavailable due to security settings
        storage = false
      @_options = $.extend
        name: 'tour'
        steps: []
        container: 'body'
        autoscroll: true
        keyboard: true
        storage: storage
        debug: false
        backdrop: false
        backdropContainer: 'body'
        backdropPadding: 0
        redirect: true
        orphan: false
        duration: false
        delay: false
        basePath: ''
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
        afterSetState: (key, value) ->
        afterGetState: (key, value) ->
        afterRemoveState: (key) ->
        onStart: (tour) ->
        onEnd: (tour) ->
        onShow: (tour) ->
        onShown: (tour) ->
        onHide: (tour) ->
        onHidden: (tour) ->
        onNext: (tour) ->
        onPrev: (tour) ->
        onPause: (tour, duration) ->
        onResume: (tour, duration) ->
        onRedirectError: (tour) ->
      , options

      @_force = false
      @_inited = false
      @_current = null
      @backdrop =
        overlay: null
        $element: null
        $background: null
        backgroundShown: false
        overlayElementShown: false
      @

    # Add multiple steps
    addSteps: (steps) ->
      @addStep step for step in steps
      @

    # Add a new step
    addStep: (step) ->
      @_options.steps.push step
      @

    # Get a step by its indice
    getStep: (i) ->
      if @_options.steps[i]?
        $.extend
          id: "step-#{i}"
          path: ''
          host: ''
          placement: 'right'
          title: ''
          content: '<p></p>' # no empty as default, otherwise popover won't show up
          next: if i is @_options.steps.length - 1 then -1 else i + 1
          prev: i - 1
          animation: true
          container: @_options.container
          autoscroll: @_options.autoscroll
          backdrop: @_options.backdrop
          backdropContainer: @_options.backdropContainer
          backdropPadding: @_options.backdropPadding
          redirect: @_options.redirect
          reflexElement: @_options.steps[i].element
          orphan: @_options.orphan
          duration: @_options.duration
          delay: @_options.delay
          template: @_options.template
          onShow: @_options.onShow
          onShown: @_options.onShown
          onHide: @_options.onHide
          onHidden: @_options.onHidden
          onNext: @_options.onNext
          onPrev: @_options.onPrev
          onPause: @_options.onPause
          onResume: @_options.onResume
          onRedirectError: @_options.onRedirectError
        , @_options.steps[i]

    # Setup event bindings and continue a tour that has already started
    init: (force) ->
      @_force = force

      if @ended()
        @_debug 'Tour ended, init prevented.'
        return @

      @setCurrentStep()

      @_initMouseNavigation()
      @_initKeyboardNavigation()

      # Reshow popover on window resize using debounced resize
      @_onResize => @showStep @_current

      # Continue a tour that had started on a previous page load
      @showStep @_current unless @_current is null

      @_inited = true
      @

    # Start tour from current step
    start: (force = false) ->
      @init force unless @_inited # Backward compatibility

      if @_current is null
        promise = @_makePromise(@_options.onStart(@) if @_options.onStart?)
        @_callOnPromiseDone(promise, @showStep, 0)
      @

    # Hide current step and show next step
    next: ->
      promise = @hideStep @_current
      @_callOnPromiseDone promise, @_showNextStep

    # Hide current step and show prev step
    prev: ->
      promise = @hideStep @_current
      @_callOnPromiseDone promise, @_showPrevStep

    goTo: (i) ->
      promise = @hideStep @_current
      @_callOnPromiseDone promise, @showStep, i

    # End tour
    end: ->
      endHelper = (e) =>
        $(document).off "click.tour-#{@_options.name}"
        $(document).off "keyup.tour-#{@_options.name}"
        $(window).off "resize.tour-#{@_options.name}"
        @_setState('end', 'yes')
        @_inited = false
        @_force = false

        @_clearTimer()

        @_options.onEnd(@) if @_options.onEnd?

      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, endHelper)

    # Verify if tour is enabled
    ended: ->
      not @_force and not not @_getState 'end'

    # Restart tour
    restart: ->
      @_removeState 'current_step'
      @_removeState 'end'
      @_removeState 'redirect_to'
      @start()

    # Pause step timer
    pause: ->
      step = @getStep @_current
      return @ unless step and step.duration

      @_paused = true
      @_duration -= new Date().getTime() - @_start
      window.clearTimeout(@_timer)

      @_debug "Paused/Stopped step #{@_current + 1} timer (#{@_duration} remaining)."

      step.onPause @, @_duration if step.onPause?

    # Resume step timer
    resume: ->
      step = @getStep @_current
      return @ unless step and step.duration

      @_paused = false
      @_start = new Date().getTime()
      @_duration = @_duration or step.duration
      @_timer = window.setTimeout =>
        if @_isLast() then @next() else @end()
      , @_duration

      @_debug "Started step #{@_current + 1} timer with duration #{@_duration}"

      step.onResume @, @_duration if step.onResume? and @_duration isnt step.duration

    # Hide the specified step
    hideStep: (i) ->
      step = @getStep i
      return unless step

      @_clearTimer()

      # If onHide returns a promise, let's wait until it's done to execute
      promise = @_makePromise(step.onHide @, i if step.onHide?)

      hideStepHelper = (e) =>
        $element = $ step.element
        $element = $('body') unless $element.data('bs.popover') or $element.data('popover')
        $element
        .popover('destroy')
        .removeClass "tour-#{@_options.name}-element tour-#{@_options.name}-#{i}-element"
        $element
        .removeData('bs.popover')
        if step.reflex
          $ step.reflexElement
          .removeClass('tour-step-element-reflex')
          .off "#{@_reflexEvent(step.reflex)}.tour-#{@_options.name}"

        @_hideBackdrop() if step.backdrop

        step.onHidden(@) if step.onHidden?

      @_callOnPromiseDone promise, hideStepHelper
      promise

    # Show the specified step
    showStep: (i) ->
      if @ended()
        @_debug 'Tour ended, showStep prevented.'
        return @

      step = @getStep i
      return unless step

      skipToPrevious = i < @_current

      # If onShow returns a promise, let's wait until it's done to execute
      promise = @_makePromise(step.onShow @, i if step.onShow?)

      showStepHelper = (e) =>
        @setCurrentStep i

        # Support string or function for path
        path = switch ({}).toString.call step.path
          when '[object Function]' then step.path()
          when '[object String]' then @_options.basePath + step.path
          else step.path

        # Redirect to step path if not already there
        if @_isRedirect step.host, path, document.location
          @_redirect step, i, path

          return unless @_isJustPathHashDifferent(step.host, path, document.location)

        # Skip if step is orphan and orphan options is false
        if @_isOrphan step
          if step.orphan is false
            @_debug """Skip the orphan step #{@_current + 1}.
            Orphan option is false and the element does not exist or is hidden."""
            if skipToPrevious then @_showPrevStep() else @_showNextStep()
            return

          @_debug "Show the orphan step #{@_current + 1}. Orphans option is true."

        # Show backdrop
        @_showBackdrop(step) if step.backdrop

        showPopoverAndOverlay = =>
          return if @getCurrentStep() isnt i or @ended()

          @_showOverlayElement step if step.element? and step.backdrop
          @_showPopover step, i
          step.onShown @ if step.onShown?
          @_debug "Step #{@_current + 1} of #{@_options.steps.length}"

        if step.autoscroll
          @_scrollIntoView step.element, showPopoverAndOverlay
        else
          showPopoverAndOverlay()

        # Play step timer
        @resume() if step.duration

      if step.delay
        @_debug "Wait #{step.delay} milliseconds to show the step #{@_current + 1}"
        window.setTimeout =>
          @_callOnPromiseDone promise, showStepHelper
        , step.delay
      else
        @_callOnPromiseDone promise, showStepHelper

      promise

    getCurrentStep: ->
      @_current

    # Setup current step variable
    setCurrentStep: (value) ->
      if value?
        @_current = value
        @_setState 'current_step', value
      else
        @_current = @_getState 'current_step'
        @_current = if @_current is null then null else parseInt @_current, 10
      @

    # Manually trigger a redraw on the overlay element
    redraw: ->
      @_showOverlayElement(@getStep(@getCurrentStep()).element, true)

    # Set a state in storage
    _setState: (key, value) ->
      if @_options.storage
        keyName = "#{@_options.name}_#{key}"
        try @_options.storage.setItem keyName, value
        catch e
          if e.code is DOMException.QUOTA_EXCEEDED_ERR
            @_debug 'LocalStorage quota exceeded. State storage failed.'
        @_options.afterSetState keyName, value
      else
        @_state ?= {}
        @_state[key] = value

    # Remove the current state from the storage layer
    _removeState: (key) ->
      if @_options.storage
        keyName = "#{@_options.name}_#{key}"
        @_options.storage.removeItem keyName
        @_options.afterRemoveState keyName
      else
        delete @_state[key] if @_state?

    # Get the current state from the storage layer
    _getState: (key) ->
      if @_options.storage
        keyName = "#{@_options.name}_#{key}"
        value = @_options.storage.getItem keyName
      else
        value = @_state[key] if @_state?

      value = null if value is undefined or value is 'null'

      @_options.afterGetState key, value
      return value

    # Show next step
    _showNextStep: ->
      step = @getStep @_current
      showNextStepHelper = (e) => @showStep step.next

      promise = @_makePromise(step.onNext @ if step.onNext?)
      @_callOnPromiseDone promise, showNextStepHelper

    # Show prev step
    _showPrevStep: ->
      step = @getStep @_current
      showPrevStepHelper = (e) => @showStep step.prev

      promise = @_makePromise(step.onPrev @ if step.onPrev?)
      @_callOnPromiseDone promise, showPrevStepHelper

    # Print message in console
    _debug: (text) ->
      window.console.log "Bootstrap Tour '#{@_options.name}' | #{text}" if @_options.debug

    # Check if step path equals current document path
    _isRedirect: (host, path, location) ->
      if host isnt ''
        return true if @_isHostDifferent(host, location.href)

      currentPath = [
        location.pathname,
        location.search,
        location.hash
      ].join('')

      path? and path isnt '' and (
        (({}).toString.call(path) is '[object RegExp]' and not path.test(currentPath)) or
        (({}).toString.call(path) is '[object String]' and @_isPathDifferent(path, currentPath))
      )

    _isHostDifferent: (host, currentURL) ->
      @_getProtocol(host) isnt @_getProtocol(currentURL) or
      @_getHost(host) isnt @_getHost(currentURL)

    _isPathDifferent: (path, currentPath) ->
      @_getPath(path) isnt @_getPath(currentPath) or not
      @_equal(@_getQuery(path), @_getQuery(currentPath)) or not
      @_equal(@_getHash(path), @_getHash(currentPath))

    _isJustPathHashDifferent: (host, path, location) ->
      if host isnt ''
        return false if @_isHostDifferent(host, location.href)

      currentPath = [
        location.pathname,
        location.search,
        location.hash
      ].join('')

      if ({}).toString.call(path) is '[object String]'
        return @_getPath(path) is @_getPath(currentPath) and
          @_equal(@_getQuery(path), @_getQuery(currentPath)) and not
          @_equal(@_getHash(path), @_getHash(currentPath))

      false

    # Execute the redirect
    _redirect: (step, i, path) ->
      if $.isFunction step.redirect
        step.redirect.call this, path
      else if step.redirect is true
        @_debug "Redirect to #{step.host}#{path}"
        if @_getState('redirect_to') is "#{i}"
          @_debug "Error redirection loop to #{path}"
          @_removeState 'redirect_to'

          step.onRedirectError @ if step.onRedirectError?
        else
          @_setState 'redirect_to', "#{i}"
          document.location.href = "#{step.host}#{path}"

    _isOrphan: (step) ->
      # Do not check for is(':hidden') on svg elements. jQuery does not work properly on svg.
      not step.element? or
      not $(step.element).length or
      $(step.element).is(':hidden') and
      ($(step.element)[0].namespaceURI isnt 'http://www.w3.org/2000/svg')

    _isLast: ->
      @_current < @_options.steps.length - 1

    # Show step popover
    _showPopover: (step, i) ->
      # Remove previously existing tour popovers. This prevents displaying of
      # multiple inactive popovers when user navigates the tour too quickly.
      $(".tour-#{@_options.name}").remove()

      options = $.extend {}, @_options
      isOrphan = @_isOrphan step

      step.template = @_template step, i

      if isOrphan
        step.element = 'body'
        step.placement = 'top'

      $element = $ step.element
      $element.addClass "tour-#{@_options.name}-element tour-#{@_options.name}-#{i}-element"

      $.extend options, step.options if step.options
      if step.reflex and not isOrphan
        $ step.reflexElement
        .addClass('tour-step-element-reflex')
        .off("#{@_reflexEvent(step.reflex)}.tour-#{@_options.name}")
        .on "#{@_reflexEvent(step.reflex)}.tour-#{@_options.name}", =>
          if @_isLast() then @next() else @end()

      shouldAddSmart = step.smartPlacement is true and step.placement.search(/auto/i) is -1

      $element
      .popover(
        placement: if shouldAddSmart then "auto #{step.placement}" else step.placement
        trigger: 'manual'
        title: step.title
        content: step.content
        html: true
        animation: step.animation
        container: step.container
        template: step.template
        selector: step.element
      )
      .popover 'show'

      # Tip adjustment
      $tip = if $element.data 'bs.popover' then $element.data('bs.popover').tip() else $element.data('popover').tip()
      $tip.attr 'id', step.id
      @_reposition $tip, step
      @_center $tip if isOrphan

    # Get popover template
    _template: (step, i) ->
      template = step.template

      if @_isOrphan(step) and ({}).toString.call(step.orphan) isnt '[object Boolean]'
        template = step.orphan

      $template = if $.isFunction template then $(template i, step) else $(template)
      $navigation = $template.find '.popover-navigation'
      $prev = $navigation.find '[data-role="prev"]'
      $next = $navigation.find '[data-role="next"]'
      $resume = $navigation.find '[data-role="pause-resume"]'

      $template.addClass 'orphan' if @_isOrphan step
      $template.addClass "tour-#{@_options.name} tour-#{@_options.name}-#{i}"
      $template.addClass "tour-#{@_options.name}-reflex" if step.reflex
      if step.prev < 0
        $prev.addClass('disabled')
        $prev.prop('disabled',true)
      if step.next < 0
        $next.addClass('disabled')
        $next.prop('disabled',true)
      $resume.remove() unless step.duration
      $template.clone().wrap('<div>').parent().html()

    _reflexEvent: (reflex) ->
      if ({}).toString.call(reflex) is '[object Boolean]' then 'click' else reflex

    # Prevent popover from crossing over the edge of the window
    _reposition: ($tip, step) ->
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
      if step.placement is 'bottom' or step.placement is 'top'
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
      $element = $(element)
      return callback() unless $element.length

      $window = $(window)
      offsetTop = $element.offset().top
      windowHeight = $window.height()
      scrollTop = Math.max(0, offsetTop - (windowHeight / 2))

      @_debug "Scroll into view. ScrollTop: #{scrollTop}. Element offset: #{offsetTop}. Window height: #{windowHeight}."
      counter = 0
      $('body, html').stop(true, true).animate
        scrollTop: Math.ceil(scrollTop),
        =>
          if ++counter is 2
            callback()
            @_debug """Scroll into view.
            Animation end element offset: #{$element.offset().top}.
            Window height: #{$window.height()}."""

    # Debounced window resize
    _onResize: (callback, timeout) ->
      $(window).on "resize.tour-#{@_options.name}", ->
        clearTimeout(timeout)
        timeout = setTimeout(callback, 100)

    # Event bindings for mouse navigation
    _initMouseNavigation: ->
      _this = @

      # Go to next step after click on element with attribute 'data-role=next'
      # Go to previous step after click on element with attribute 'data-role=prev'
      # End tour after click on element with attribute 'data-role=end'
      # Pause/resume tour after click on element with attribute 'data-role=pause-resume'
      $(document)
      .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='prev']")
      .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='next']")
      .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='end']")
      .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='pause-resume']")
      .on "click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='next']", (e) =>
        e.preventDefault()
        @next()
      .on "click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='prev']", (e) =>
        e.preventDefault()
        @prev()
      .on "click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='end']", (e) =>
        e.preventDefault()
        @end()
      .on "click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role='pause-resume']", (e) ->
        e.preventDefault()
        $this = $ @

        $this.text if _this._paused then $this.data 'pause-text' else $this.data 'resume-text'
        if _this._paused then _this.resume() else _this.pause()

    # Keyboard navigation
    _initKeyboardNavigation: ->
      return unless @_options.keyboard

      $(document).on "keyup.tour-#{@_options.name}", (e) =>
        return unless e.which

        switch e.which
          when 39
            e.preventDefault()
            if @_isLast() then @next() else @end()
          when 37
            e.preventDefault()
            @prev() if @_current > 0
          when 27
            e.preventDefault()
            @end()

    # Checks if the result of a callback is a promise
    _makePromise: (result) ->
      if result and $.isFunction(result.then) then result else null

    _callOnPromiseDone: (promise, cb, arg) ->
      if promise
        promise.then (e) =>
          cb.call(@, arg)
      else
        cb.call(@, arg)

    _showBackdrop: (step) ->
      return if @backdrop.backgroundShown

      @backdrop = $ '<div>', class: 'tour-backdrop'
      @backdrop.backgroundShown = true
      $(step.backdropContainer).append @backdrop

    _hideBackdrop: ->
      @_hideOverlayElement()
      @_hideBackground()

    _hideBackground: ->
      if @backdrop
        @backdrop.remove()
        @backdrop.overlay = null
        @backdrop.backgroundShown = false

    _showOverlayElement: (step, force) ->
      $element = $ step.element

      return if not $element or $element.length is 0 or @backdrop.overlayElementShown and not force

      if !@backdrop.overlayElementShown
        @backdrop.$element = $element.addClass 'tour-step-backdrop'
        @backdrop.$background = $ '<div>', class: 'tour-step-background'
        @backdrop.$background.appendTo(step.backdropContainer)
        @backdrop.overlayElementShown = true

      elementData =
        width: $element.innerWidth()
        height: $element.innerHeight()
        offset: $element.offset()

      elementData = @_applyBackdropPadding step.backdropPadding, elementData if step.backdropPadding
      @backdrop
      .$background
      .width(elementData.width)
      .height(elementData.height)
      .offset(elementData.offset)

    _hideOverlayElement: ->
      return unless @backdrop.overlayElementShown

      @backdrop.$element.removeClass 'tour-step-backdrop'
      @backdrop.$background.remove()
      @backdrop.$element = null
      @backdrop.$background = null
      @backdrop.overlayElementShown = false

    _applyBackdropPadding: (padding, data) ->
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

    _clearTimer: ->
      window.clearTimeout @_timer
      @_timer = null
      @_duration = null

    _getProtocol: (url) ->
      url = url.split('://')
      return if url.length > 1 then url[0] else 'http'

    _getHost: (url) ->
      url = url.split('//')
      url = if url.length > 1 then  url[1] else url[0]

      return url.split('/')[0]

    _getPath: (path) ->
      return path.replace(/\/?$/, '').split('?')[0].split('#')[0]

    _getQuery: (path) ->
      return @_getParams(path, '?')

    _getHash: (path) ->
      return @_getParams(path, '#')

    _getParams: (path, start) ->
      params = path.split(start)
      return {} if params.length is 1

      params = params[1].split('&')
      paramsObject = {}

      for param in params
        param = param.split('=')
        paramsObject[param[0]] = param[1] or ''

      return paramsObject

    _equal: (obj1, obj2) ->
      if ({}).toString.call(obj1) is '[object Object]' and
      ({}).toString.call(obj2) is '[object Object]'
        for k,v of obj1
          return false if obj2[k] isnt v
        for k,v of obj2
          return false if obj1[k] isnt v
        return true

      return obj1 is obj2
  window.Tour = Tour

) jQuery, window

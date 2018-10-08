((window, factory) ->
  if typeof define is 'function' and define.amd
    define ['jquery'], (jQuery) -> (window.Tour = factory(jQuery))
  else if typeof exports is 'object'
    module.exports = factory(require('jquery'))
  else
    window.Tour = factory(window.jQuery)
)(window, ($) ->
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
          <h3 class="popover-header"></h3>
          <div class="popover-body"></div>
          <div class="popover-navigation">
            <div class="btn-group">
              <button class="btn btn-sm btn-secondary" data-role="prev">&laquo; Prev</button>
              <button class="btn btn-sm btn-secondary" data-role="next">Next &raquo;</button>
              <button class="btn btn-sm btn-secondary"
                      data-role="pause-resume"
                      data-pause-text="Pause"
                      data-resume-text="Resume">Pause</button>
            </div>
            <button class="btn btn-sm btn-secondary" data-role="end">End tour</button>
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
      @backdrops = []
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
          backdropElement: @_options.steps[i].element
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
      promise = @hideStep @_current, @_current+1
      @_callOnPromiseDone promise, @_showNextStep

    # Hide current step and show prev step
    prev: ->
      promise = @hideStep @_current, @_current-1
      @_callOnPromiseDone promise, @_showPrevStep

    goTo: (i) ->
      promise = @hideStep @_current, i
      @_callOnPromiseDone promise, @showStep, i

    # End tour
    end: ->
      endHelper = (e) =>
        $(document).off "click.tour-#{@_options.name}"
        $(document).off "keyup.tour-#{@_options.name}"
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
    hideStep: (i, iNext) ->
      step = @getStep i
      return unless step

      @_clearTimer()

      # If onHide returns a promise, let's wait until it's done to execute
      promise = @_makePromise(step.onHide @, i if step.onHide?)

      hideStepHelper = (e) =>
        $element = $ step.element
        $element = $('body') unless $element.data('bs.popover')
        $element
          .popover('dispose')
          .removeClass("tour-#{@_options.name}-element tour-#{@_options.name}-#{i}-element")
          .removeData('bs.popover')

        if step.reflex
          $ step.reflexElement
          .removeClass('tour-step-element-reflex')
          .off "#{@_reflexEvent(step.reflex)}.tour-#{@_options.name}"

        if step.backdrop
          next_step = iNext? and @getStep iNext
          if !next_step or !next_step.backdrop or next_step.backdropElement != step.backdropElement
            @_hideOverlayElement(step)

        step.onHidden(@) if step.onHidden?

      hideDelay = step.delay.hide || step.delay

      if ({}).toString.call(hideDelay) is '[object Number]' and hideDelay > 0
        @_debug "Wait #{hideDelay} milliseconds to hide the step #{@_current + 1}"
        window.setTimeout =>
          @_callOnPromiseDone promise, hideStepHelper
        , hideDelay
      else
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

      @setCurrentStep i

      # Support string or function for path
      path = switch ({}).toString.call step.path
        when '[object Function]' then step.path()
        when '[object String]' then @_options.basePath + step.path
        else step.path

      # Redirect to step path if not already there
      if step.redirect and @_isRedirect step.host, path, document.location
        @_redirect step, i, path

        return unless @_isJustPathHashDifferent(step.host, path, document.location)

      showStepHelper = (e) =>
        # Skip if step is orphan and orphan options is false
        if @_isOrphan step
          if step.orphan is false
            @_debug """Skip the orphan step #{@_current + 1}.
            Orphan option is false and the element does not exist or is hidden."""
            if skipToPrevious then @_showPrevStep() else @_showNextStep()
            return

          @_debug "Show the orphan step #{@_current + 1}. Orphans option is true."

        # Show backdrop
        # @_showBackdrop(step) if step.backdrop

        if step.autoscroll
          @_scrollIntoView i
        else
          @_showPopoverAndOverlay i

        # Play step timer
        @resume() if step.duration

      showDelay = step.delay.show || step.delay

      if ({}).toString.call(showDelay) is '[object Number]' and showDelay > 0
        @_debug "Wait #{showDelay} milliseconds to show the step #{@_current + 1}"
        window.setTimeout =>
          @_callOnPromiseDone promise, showStepHelper
        , showDelay
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
      @_showOverlayElement(@getStep(@getCurrentStep()))

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
      return true if host? and host isnt '' and (
        (({}).toString.call(host) is '[object RegExp]' and not host.test(location.origin)) or
        (({}).toString.call(host) is '[object String]' and @_isHostDifferent(host, location))
      )

      currentPath = [
        location.pathname,
        location.search,
        location.hash
      ].join('')

      path? and path isnt '' and (
        (({}).toString.call(path) is '[object RegExp]' and not path.test(currentPath)) or
        (({}).toString.call(path) is '[object String]' and @_isPathDifferent(path, currentPath))
      )

    _isHostDifferent: (host, location) ->
      switch ({}).toString.call(host)
        when '[object RegExp]'
          not host.test(location.origin)
        when '[object String]'
          @_getProtocol(host) isnt @_getProtocol(location.href) or
          @_getHost(host) isnt @_getHost(location.href)
        else
          true

    _isPathDifferent: (path, currentPath) ->
      @_getPath(path) isnt @_getPath(currentPath) or not
      @_equal(@_getQuery(path), @_getQuery(currentPath)) or not
      @_equal(@_getHash(path), @_getHash(currentPath))

    _isJustPathHashDifferent: (host, path, location) ->
      if host? and host isnt ''
        return false if @_isHostDifferent(host, location)

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
      else
        href = if ({}).toString.call(step.host) is '[object String]' then "#{step.host}#{path}" else path
        @_debug "Redirect to #{href}"

        if @_getState('redirect_to') is "#{i}"
          @_debug "Error redirection loop to #{path}"
          @_removeState 'redirect_to'

          step.onRedirectError @ if step.onRedirectError?
        else
          @_setState 'redirect_to', "#{i}"
          document.location.href = href

    _isOrphan: (step) ->
      # Do not check for is(':hidden') on svg elements. jQuery does not work properly on svg.
      not step.element? or
      not $(step.element).length or
      $(step.element).is(':hidden') and
      ($(step.element)[0].namespaceURI isnt 'http://www.w3.org/2000/svg')

    _isLast: ->
      @_current < @_options.steps.length - 1

    _showPopoverAndOverlay: (i) =>
      return if @getCurrentStep() isnt i or @ended()

      step = @getStep i

      @_showOverlayElement step if step.backdrop
      @_showPopover step, i
      step.onShown @ if step.onShown?
      @_debug "Step #{@_current + 1} of #{@_options.steps.length}"

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

      $element
      .popover(
        placement: step.placement
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
      $tip = $($element.data('bs.popover').getTipElement())
      $tip.attr 'id', step.id

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
          .prop('disabled', true)
          .prop('tabindex', -1)

      if step.next < 0
        $next.addClass('disabled')
          .prop('disabled', true)
          .prop('tabindex', -1)

      $resume.remove() unless step.duration
      $template.clone().wrap('<div>').parent().html()

    _reflexEvent: (reflex) ->
      if ({}).toString.call(reflex) is '[object Boolean]' then 'click' else reflex

    # Scroll to the popup if it is not in the viewport
    _scrollIntoView: (i) ->
      step = @getStep i
      $element = $(step.element)
      return @_showPopoverAndOverlay(i) unless $element.length

      $window = $(window)
      offsetTop = $element.offset().top
      height = $element.outerHeight()
      windowHeight = $window.height()
      scrollTop = 0

      switch step.placement.replace('auto','').trim()
        when 'top'
          scrollTop = Math.max(0, offsetTop - (windowHeight / 2))
        when 'left', 'right'
          scrollTop = Math.max(0, (offsetTop + height / 2) - (windowHeight / 2))
        when 'bottom'
          scrollTop = Math.max(0, (offsetTop + height) - (windowHeight / 2))

      @_debug "Scroll into view. ScrollTop: #{scrollTop}. Element offset: #{offsetTop}. Window height: #{windowHeight}."
      counter = 0
      $('body, html').stop(true, true).animate
        scrollTop: Math.ceil(scrollTop),
        =>
          if ++counter is 2
            @_showPopoverAndOverlay(i)
            @_debug """Scroll into view.
            Animation end element offset: #{$element.offset().top}.
            Window height: #{$window.height()}."""

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
        @prev() if @_current > 0
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

    # Checks if the result of a callback is a promise
    _makePromise: (result) ->
      if result and $.isFunction(result.then) then result else null

    _callOnPromiseDone: (promise, cb, arg) ->
      if promise
        promise.then (e) =>
          cb.call(@, arg)
      else
        cb.call(@, arg)

    _showBackground: (step, data) ->
      height = $(document).height()
      width = $(document).width()
      for pos in ['top', 'bottom', 'left', 'right']
        $backdrop = @backdrops[pos] ?= $('<div>', class: "tour-backdrop #{pos}")
        $(step.backdropContainer).append($backdrop)

        switch pos
          when 'top'
            $backdrop
            .height(if data.offset.top > 0 then data.offset.top else 0)
            .width(width)
            .offset(top: 0, left: 0)
          when 'bottom'
            $backdrop
            .offset(top: data.offset.top + data.height, left: 0)
            .height(height - (data.offset.top + data.height))
            .width(width)
          when 'left'
            $backdrop
            .offset(top: data.offset.top, left: 0)
            .height(data.height)
            .width(if data.offset.left > 0 then data.offset.left else 0)
          when 'right'
            $backdrop
            .offset(top: data.offset.top, left: data.offset.left + data.width)
            .height(data.height)
            .width(width - (data.offset.left + data.width))

    _showOverlayElement: (step) ->
      $backdropElement = $ step.backdropElement

      if $backdropElement.length is 0
        elementData =
          width: 0
          height: 0
          offset:
            top: 0
            left: 0
      else
        elementData =
          width: $backdropElement.innerWidth()
          height: $backdropElement.innerHeight()
          offset: $backdropElement.offset()

        $backdropElement.addClass 'tour-step-backdrop'
        elementData = @_applyBackdropPadding step.backdropPadding, elementData if step.backdropPadding

      @_showBackground(step, elementData)

    _hideOverlayElement: (step) ->
      $(step.backdropElement).removeClass 'tour-step-backdrop'

      for pos, $backdrop of @backdrops
        $backdrop.remove() if $backdrop and $backdrop.remove isnt undefined

      @backdrops = []

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
      if ({}).toString.call(obj1) is '[object Object]' and ({}).toString.call(obj2) is '[object Object]'
        obj1Keys = Object.keys(obj1)
        obj2Keys = Object.keys(obj2)
        return false if obj1Keys.length isnt obj2Keys.length

        for k,v of obj1
          return false if not @_equal(obj2[k], v)

        return true
      else if ({}).toString.call(obj1) is '[object Array]' and ({}).toString.call(obj2) is '[object Array]'
        return false if obj1.length isnt obj2.length

        for v,k in obj1
          return false if not @_equal(v, obj2[k])

        return true
      else
        return obj1 is obj2

  Tour
)

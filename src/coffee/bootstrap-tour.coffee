(($, window) ->
  document = window.document

  class Tour
    constructor: (options) ->
      @_options = $.extend({
        name: "tour"
        container: "body"
        keyboard: true
        storage: window.localStorage
        debug: false
        backdrop: false
        redirect: true
        orphan: false
        duration: false
        basePath: ""
        template: "<div class='popover'>
          <div class='arrow'></div>
          <h3 class='popover-title'></h3>
          <div class='popover-content'></div>
          <div class='popover-navigation'>
            <div class='btn-group'>
              <button class='btn btn-sm btn-default' data-role='prev'>&laquo; Prev</button>
              <button class='btn btn-sm btn-default' data-role='next'>Next &raquo;</button>
              <button class='btn btn-sm btn-default' data-role='pause-resume'
                data-pause-text='Pause'
                data-resume-text='Resume'
              >Pause</button>
            </div>
            <button class='btn btn-sm btn-default' data-role='end'>End tour</button>
          </div>
        </div>"
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
      }, options)

      @_force = false
      @_inited = false
      @_steps = []
      @backdrop =
        overlay: null
        $element: null
        $background: null
        backgroundShown: false
        overlayElementShown: false

    # Set a state in storage
    setState: (key, value) ->
      if @_options.storage
        keyName = "#{@_options.name}_#{key}"
        try @_options.storage.setItem(keyName, value)
        catch e
          if e.code is DOMException.QUOTA_EXCEEDED_ERR
            @debug "LocalStorage quota exceeded. setState failed."
        @_options.afterSetState(keyName, value)
      else
        @_state ?= {}
        @_state[key] = value

    # Remove the current state from the storage layer
    removeState: (key) ->
      if @_options.storage
        keyName = "#{@_options.name}_#{key}"
        @_options.storage.removeItem(keyName)
        @_options.afterRemoveState(keyName)
      else
        delete @_state[key] if @_state?

    # Get the current state from the storage layer
    getState: (key) ->
      if @_options.storage
        keyName = "#{@_options.name}_#{key}"
        value = @_options.storage.getItem(keyName)
      else
        value = @_state[key] if @_state?

      value = null if value is undefined or value == "null"

      @_options.afterGetState(key, value)
      return value

    # Add multiple steps
    addSteps: (steps) ->
      @addStep step for step in steps

    # Add a new step
    addStep: (step) ->
      @_steps.push step

    # Get a step by its indice
    getStep: (i) ->
      $.extend({
        id: "step-#{i}"
        path: ""
        placement: "right"
        title: ""
        content: "<p></p>" # no empty as default, otherwise popover won't show up
        next: if i == @_steps.length - 1 then -1 else i + 1
        prev: i - 1
        animation: true
        container: @_options.container
        backdrop: @_options.backdrop
        redirect: @_options.redirect
        orphan: @_options.orphan
        duration: @_options.duration
        template: @_options.template
        onShow: @_options.onShow
        onShown: @_options.onShown
        onHide: @_options.onHide
        onHidden: @_options.onHidden
        onNext: @_options.onNext
        onPrev: @_options.onPrev
        onPause: @_options.onPause
        onResume: @_options.onResume
      }, @_steps[i]) if @_steps[i]?

    # Setup event bindings and continue a tour that has already started
    init: (force) ->
      @_force = force

      return @_debug "Tour ended, init prevented." if @ended()

      @setCurrentStep()

      @_setupMouseNavigation()
      @_setupKeyboardNavigation()

      # Reshow popover on window resize using debounced resize
      @_onResize( => @showStep(@_current))

      # Continue a tour that had started on a previous page load
      @showStep(@_current) unless @_current == null

      @_inited = true
      @

    # Start tour from current step
    start: (force = false) ->
      @init(force) unless @_inited # Backward compatibility

      if @_current == null
        promise = @_makePromise(@_options.onStart(@) if @_options.onStart?)
        @_callOnPromiseDone(promise, @showStep, 0)

    # Hide current step and show next step
    next: ->
      return @_debug "Tour ended, next prevented." if @ended()

      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, @_showNextStep)

    # Hide current step and show prev step
    prev: ->
      return @_debug "Tour ended, prev prevented." if @ended()

      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, @_showPrevStep)

    goTo: (i) ->
      return @_debug "Tour ended, goTo prevented." if @ended()

      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, @showStep, i)

    # End tour
    end: ->
      endHelper = (e) =>
        $(document).off "click.tour-#{@_options.name}"
        $(document).off "keyup.tour-#{@_options.name}"
        $(window).off "resize.tour-#{@_options.name}"
        @setState("end", "yes")
        @_inited = false
        @_force = false

        @_clearTimer()

        @_options.onEnd(@) if @_options.onEnd?

      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, endHelper)

    # Verify if tour is enabled
    ended: ->
      ! @_force and !! @getState("end")

    # Restart tour
    restart: ->
      @removeState("current_step")
      @removeState("end")
      @setCurrentStep(0)
      @start()

    # Pause step timer
    pause: ->
      step = @getStep(@_current)
      return unless step and step.duration

      @_paused = true
      @_duration -= new Date().getTime() - @_start
      window.clearTimeout(@_timer)

      @_debug "Paused/Stopped step #{@_current + 1} timer (#{@_duration} remaining)."

      step.onPause(@, @_duration) if step.onPause?

    # Resume step timer
    resume: ->
      step = @getStep(@_current)
      return unless step and step.duration

      @_paused = false
      @_start = new Date().getTime()
      @_duration = @_duration or step.duration
      @_timer = window.setTimeout( =>
        if @_isLast() then @next() else @end()
      , @_duration)

      @_debug "Started step #{@_current + 1} timer with duration #{@_duration}"

      step.onResume(@, @_duration) if step.onResume? and @_duration isnt step.duration

    # Hide the specified step
    hideStep: (i) ->
      step = @getStep(i)
      return unless step

      @_clearTimer()

      # If onHide returns a promise, let's wait until it's done to execute
      promise = @_makePromise(step.onHide(@, i) if step.onHide?)

      hideStepHelper = (e) =>
        $element = $(step.element)
        $element = $("body") unless $element.data("bs.popover") or $element.data("popover")
        $element.popover("destroy")
        $element.css("cursor", "").off "click.tour-#{@_options.name}" if step.reflex

        # Hide backdrop
        @_hideBackdrop() if step.backdrop

        step.onHidden(@) if step.onHidden?

      @_callOnPromiseDone(promise, hideStepHelper)

      promise

    # Show the specified step
    showStep: (i) ->
      step = @getStep(i)
      return unless step

      skipToPrevious = i < @_current

      # If onShow returns a promise, let's wait until it's done to execute
      promise = @_makePromise(step.onShow(@, i) if step.onShow?)

      showStepHelper = (e) =>
        @setCurrentStep(i)

        # Support string or function for path
        path = if $.isFunction(step.path) then step.path.call() else @_options.basePath + step.path

        # Redirect to step path if not already there
        current_path = [document.location.pathname, document.location.hash].join("")
        if @_isRedirect(path, current_path)
          @_redirect(step, path)
          return

        # Skip if step is orphan and orphan options is false
        if @_isOrphan(step)
          if ( ! step.orphan)
            @_debug "Skip the orphan step #{@_current + 1}. Orphan option is false and the element doesn't exist or is hidden."
            if skipToPrevious then @_showPrevStep() else @_showNextStep()
            return

          @_debug "Show the orphan step #{@_current + 1}. Orphans option is true."

        # Show backdrop
        @_showBackdrop(step.element unless @_isOrphan(step)) if step.backdrop

        @_scrollIntoView(step.element, =>
          @_showOverlayElement(step.element) if step.element? and step.backdrop

          # Show popover
          @_showPopover(step, i)
          step.onShown(@) if step.onShown?
          @_debug "Step #{@_current + 1} of #{@_steps.length}"
        )

        # Play step timer
        @resume() if step.duration

      @_callOnPromiseDone(promise, showStepHelper)

      promise

    # Setup current step variable
    setCurrentStep: (value) ->
      if value?
        @_current = value
        @setState("current_step", value)
      else
        @_current = @getState("current_step")
        @_current = if @_current == null then null else parseInt(@_current, 10)
      @

    # Show next step
    _showNextStep: ->
      step = @getStep(@_current)
      showNextStepHelper = (e) => @showStep(step.next)

      promise = @_makePromise (step.onNext(@) if step.onNext?)
      @_callOnPromiseDone(promise, showNextStepHelper)

    # Show prev step
    _showPrevStep: ->
      step = @getStep(@_current)
      showPrevStepHelper = (e) => @showStep(step.prev)

      promise = @_makePromise (step.onPrev(@) if step.onPrev?)
      @_callOnPromiseDone(promise, showPrevStepHelper)

    # Print message in console
    _debug: (text) ->
      window.console.log "Bootstrap Tour '#{@_options.name}' | #{text}" if @_options.debug

    # Check if step path equals current document path
    _isRedirect: (path, currentPath) ->
      path? and path isnt "" and
        path.replace(/\?.*$/, "").replace(/\/?$/, "") isnt currentPath.replace(/\/?$/, "")

    # Execute the redirect
    _redirect: (step, path) ->
      if $.isFunction(step.redirect)
        step.redirect.call(this, path)

      else if step.redirect == true
        @_debug "Redirect to #{path}"
        document.location.href = path

    _isOrphan: (step) ->
      # Do not check for is(":hidden") on svg elements. jQuery does not work properly on svg.
      ! step.element? || ! $(step.element).length || $(step.element).is(":hidden") && ($(step.element)[0].namespaceURI != "http://www.w3.org/2000/svg")

    _isLast: ->
      @_current < @_steps.length - 1

    # Show step popover
    _showPopover: (step, i) ->
      options = $.extend {}, @_options
      $template = if $.isFunction(step.template) then $(step.template(i, step)) else $(step.template)
      $navigation = $template.find(".popover-navigation")
      isOrphan = @_isOrphan(step)

      if isOrphan
        step.element = "body"
        step.placement = "top"
        $template = $template.addClass("orphan")

      $element = $(step.element)

      $template.addClass("tour-#{@_options.name}")

      $.extend options, step.options if step.options

      if step.reflex
        $element.css("cursor", "pointer").on "click.tour-#{@_options.name}", =>
          if @_isLast() then @next() else @end()

      $navigation.find("*[data-role=prev]").addClass("disabled") if step.prev < 0
      $navigation.find("*[data-role=next]").addClass("disabled") if step.next < 0
      $navigation.find("*[data-role='pause-resume']").remove() unless step.duration

      step.template = $template.clone().wrap("<div>").parent().html()

      $element.popover({
        placement: step.placement
        trigger: "manual"
        title: step.title
        content: step.content
        html: true
        animation: step.animation
        container: step.container
        template: step.template
        selector: step.element
      }).popover("show")

      $tip = if $element.data("bs.popover") then $element.data("bs.popover").tip() else $element.data("popover").tip()
      $tip.attr("id", step.id)
      @_reposition($tip, step)

      @_center($tip) if isOrphan

    # Prevent popover from crossing over the edge of the window
    _reposition: ($tip, step) ->
      offsetWidth = $tip[0].offsetWidth
      offsetHeight = $tip[0].offsetHeight

      tipOffset = $tip.offset()
      originalLeft = tipOffset.left
      originalTop = tipOffset.top
      offsetBottom = $(document).outerHeight() - tipOffset.top - $tip.outerHeight()
      tipOffset.top = tipOffset.top + offsetBottom if offsetBottom < 0
      offsetRight = $("html").outerWidth() - tipOffset.left - $tip.outerWidth()
      tipOffset.left = tipOffset.left + offsetRight if offsetRight < 0

      tipOffset.top = 0 if tipOffset.top < 0
      tipOffset.left = 0 if tipOffset.left < 0

      $tip.offset(tipOffset)

      # Reposition the arrow
      if step.placement == "bottom" or step.placement == "top"
        @_replaceArrow($tip, (tipOffset.left - originalLeft) * 2, offsetWidth, "left") if originalLeft != tipOffset.left
      else
        @_replaceArrow($tip, (tipOffset.top - originalTop) * 2, offsetHeight, "top") if originalTop != tipOffset.top

    # Center popover in the page
    _center: ($tip) ->
      $tip.css("top", $(window).outerHeight() / 2 - $tip.outerHeight() / 2)

    # Copy pasted from bootstrap-tooltip.js with some alterations
    _replaceArrow: ($tip, delta, dimension, position)->
      $tip
        .find(".arrow")
        .css(position, if delta then 50 * (1 - delta / dimension) + "%" else "")

    # Scroll to the popup if it is not in the viewport
    _scrollIntoView: (element, callback) ->
      return callback() unless element

      $element = $(element)
      $window = $(window)
      offsetTop = $element.offset().top
      windowHeight = $window.height()
      scrollTop = Math.max(0, offsetTop - (windowHeight / 2))

      @_debug "Scroll into view. ScrollTop: #{scrollTop}. Element offset: #{offsetTop}. Window height: #{windowHeight}."
      $("body").stop().animate
        scrollTop: Math.ceil(scrollTop),
        =>
          callback()
          @_debug "Scroll into view. Animation end element offset: #{$element.offset().top}. Window height: #{$window.height()}."

    # Debounced window resize
    _onResize: (callback, timeout) ->
      $(window).on "resize.tour-#{@_options.name}", ->
        clearTimeout(timeout)
        timeout = setTimeout(callback, 100)

    # Event bindings for mouse navigation
    _setupMouseNavigation: ->
      _this = @

      # Go to next step after click on element with attribute 'data-role=next'
      $(document)
        .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=next]:not(.disabled)")
        .on("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=next]:not(.disabled)", (e) =>
          e.preventDefault()
          @next()
        )

      # Go to previous step after click on element with attribute 'data-role=prev'
      $(document)
        .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=prev]:not(.disabled)")
        .on("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=prev]:not(.disabled)", (e) =>
          e.preventDefault()
          @prev()
        )

      # End tour after click on element with attribute 'data-role=end'
      $(document)
        .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=end]")
        .on("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=end]", (e) =>
          e.preventDefault()
          @end()
        )

      # Pause/resume tour after click on element with attribute 'data-role=pause-resume'
      $(document)
      .off("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=pause-resume]")
      .on("click.tour-#{@_options.name}", ".popover.tour-#{@_options.name} *[data-role=pause-resume]", (e) ->
        e.preventDefault()

        $this = $(@)

        $this.text(if _this._paused then $this.data("pause-text") else $this.data("resume-text"))
        if _this._paused then _this.resume() else _this.pause()
      )

    # Keyboard navigation
    _setupKeyboardNavigation: ->
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

    _showBackdrop: (element) ->
      return if @backdrop.backgroundShown
      @backdrop = $("<div/>",
        class: "tour-backdrop"
      )
      @backdrop.backgroundShown = true
      $("body").append(@backdrop)

    _hideBackdrop: ->
      @_hideOverlayElement()
      @_hideBackground()


    _hideBackground: ->
      @backdrop.remove()
      @backdrop.overlay = null
      @backdrop.backgroundShown = false

    _showOverlayElement: (element) ->
      return if @backdrop.overlayElementShown
      @backdrop.overlayElementShown = true
      $element = $(element)
      $background = $("<div/>")

      offset = $element.offset()
      offset.top = offset.top
      offset.left = offset.left

      $background
        .width($element.innerWidth())
        .height($element.innerHeight())
        .addClass("tour-step-background")
        .offset(offset)

      $element.addClass("tour-step-backdrop")

      $("body").append($background)
      @backdrop.$element = $element
      @backdrop.$background = $background

    _hideOverlayElement: ->
      return unless @backdrop.overlayElementShown
      @backdrop.$element.removeClass("tour-step-backdrop")
      @backdrop.$background.remove()
      @backdrop.$element = null
      @backdrop.$background = null
      @backdrop.overlayElementShown = false

    _clearTimer: ->
      window.clearTimeout(@_timer)
      @_timer = null
      @_duration = null

  window.Tour = Tour

)(jQuery, window)

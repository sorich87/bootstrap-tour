(($, window) ->
  document = window.document

  class Tour
    constructor: (options) ->
      @_options = $.extend({
        name: 'tour'
        container: 'body'
        keyboard: true
        storage: window.localStorage
        debug: false
        backdrop: false
        redirect: true
        basePath: ''
        template: "<div class='popover'>
          <div class='arrow'></div>
          <h3 class='popover-title'></h3>
          <div class='popover-content'></div>
          <nav class='popover-navigation'>
            <div class='btn-group'>
              <button class='btn btn-sm btn-default' data-role='prev'>&laquo; Prev</button>
              <button class='btn btn-sm btn-default' data-role='next'>Next &raquo;</button>
            </div>
            <button class='btn btn-sm btn-default' data-role='end'>End tour</button>
          </nav>
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
      }, options)

      @_steps = []
      @setCurrentStep()
      @backdrop = {
        overlay: null
        step: null
        background: null
      }

    # Set a state in storage
    setState: (key, value) ->
      keyName = "#{@_options.name}_#{key}"
      @_options.storage.setItem(keyName, value)
      @_options.afterSetState(keyName, value)

    # Remove the current state from the storage layer
    removeState: (key) ->
      keyName = "#{@_options.name}_#{key}"
      @_options.storage.removeItem(keyName)
      @_options.afterRemoveState(keyName)

    # Get the current state from the storage layer
    getState: (key) ->
      keyName = "#{@_options.name}_#{key}"
      value = @_options.storage.getItem(keyName)

      value = null if value == undefined || value == "null"

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
      return unless @_steps[i]?

      step = $.extend({
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
        template: @_options.template
        onShow: @_options.onShow
        onShown: @_options.onShown
        onHide: @_options.onHide
        onHidden: @_options.onHidden
        onNext: @_options.onNext
        onPrev: @_options.onPrev
      }, @_steps[i])

      options = $.extend {}, @_options
      $template = if $.isFunction(step.template) then $(step.template(i, step)) else $(step.template)
      $navigation = $template.find(".popover-navigation")

      if step.options
        $.extend options, step.options

      $template.addClass("tour-#{@_options.name}")

      unless step.element? && $(step.element).length != 0 && $(step.element).is(":visible")
        step.element = 'body'
        step.placement = 'top'
        $template = $template.addClass('orphan')
        @_debug "Show the step #{@_current + 1} centered, since the element does not exist or is not visible."

      if step.prev < 0
        $navigation.find("*[data-role=prev]").addClass("disabled")

      if step.next < 0
        $navigation.find("*[data-role=next]").addClass("disabled")

      step.template = $template.clone().wrap("<div>").parent().html()

      step

    # Start tour from current step
    start: (force = false) ->
      return @_debug "Tour ended, start prevented." if @ended() && !force

      # Go to next step after click on element with attribute 'data-role=next'
      $(document)
      .off("click.tour.#{@_options.name}", ".popover *[data-role=next]")
      .on("click.tour.#{@_options.name}", ".popover *[data-role=next]:not(.disabled)", (e) =>
        e.preventDefault()
        @next()
      )

      # Go to previous step after click on element with attribute 'data-role=prev'
      $(document)
      .off("click.tour.#{@_options.name}", ".popover *[data-role=prev]")
      .on("click.tour.#{@_options.name}", ".popover *[data-role=prev]:not(.disabled)", (e) =>
        e.preventDefault()
        @prev()
      )

      # End tour after click on element with attribute 'data-role=end'
      $(document)
      .off("click.tour.#{@_options.name}", ".popover *[data-role=end]")
      .on("click.tour.#{@_options.name}", ".popover *[data-role=end]", (e) =>
        e.preventDefault()
        @end()
      )

      # Reshow popover on window resize using debounced resize
      @_onResize(=> @showStep(@_current))

      @_setupKeyboardNavigation()

      promise = @_makePromise(@_options.onStart(@) if @_options.onStart?)
      @_callOnPromiseDone(promise, @showStep, @_current)

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

    goto: (i) ->
      return @_debug "Tour ended, goto prevented." if @ended()

      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, @showStep, i)

    # End tour
    end: ->
      endHelper = (e) =>
        $(document).off "click.tour.#{@_options.name}"
        $(document).off "keyup.tour.#{@_options.name}"
        $(window).off "resize.tour.#{@_options.name}"
        @setState("end", "yes")

        @_options.onEnd(@) if @_options.onEnd?

      hidePromise = @hideStep(@_current)
      @_callOnPromiseDone(hidePromise, endHelper)

    # Verify if tour is enabled
    ended: ->
      !!@getState("end")

    # Restart tour
    restart: ->
      @removeState("current_step")
      @removeState("end")
      @setCurrentStep(0)
      @start()

    # Hide the specified step
    hideStep: (i) ->
      step = @getStep(i)

      # If onHide returns a promise, lets wait until it's done to execute
      promise = @_makePromise (step.onHide(@, i) if step.onHide?)

      hideStepHelper = (e) =>
        $element = $(step.element)
        $element.popover("destroy")
        $element.css("cursor", "").off "click.tour.#{@_options.name}" if step.reflex
        @_hideBackdrop() if step.backdrop

        step.onHidden(@) if step.onHidden?

      @_callOnPromiseDone(promise, hideStepHelper)

      promise

    # Show the specified step
    showStep: (i) ->
      step = @getStep(i)
      return unless step

      # If onShow returns a promise, lets wait until it's done to execute
      promise = @_makePromise (step.onShow(@, i) if step.onShow?)

      showStepHelper = (e) =>
        @setCurrentStep(i)

        # Support string or function for path
        path = if $.isFunction(step.path) then step.path.call() else @_options.basePath + step.path

        # Redirect to step path if not already there
        current_path = [document.location.pathname, document.location.hash].join('')
        if @_isRedirect(path, current_path)
          @_redirect(step, path)
          return

        @_showBackdrop(step.element) if step.backdrop

        # Show popover
        @_showPopover(step, i)
        step.onShown(@) if step.onShown?
        @_debug "Step #{@_current + 1} of #{@_steps.length}"

      @_callOnPromiseDone(promise, showStepHelper)

    # Setup current step variable
    setCurrentStep: (value) ->
      if value?
        @_current = value
        @setState("current_step", value)
      else
        @_current = @getState("current_step")
        if @_current == null
          @_current = 0
        else
          @_current = parseInt(@_current)

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

    # Render template
    _renderTemplate: (step, i) ->

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

    # Show step popover
    _showPopover: (step, i) ->
      $element = $(step.element)

      if step.reflex
        $element.css("cursor", "pointer").on "click.tour.#{@_options.name}", (e) =>
          if @_current < @_steps.length - 1
            @next()
          else
            @end()

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
      @_scrollIntoView($element)
      @_scrollIntoView($tip)
      @_reposition($tip, step)

    # Prevent popups from crossing over the edge of the window
    _reposition: (tip, step) ->
      original_offsetWidth = tip[0].offsetWidth
      original_offsetHeight = tip[0].offsetHeight

      tipOffset = tip.offset()
      original_left = tipOffset.left
      original_top = tipOffset.top
      offsetBottom = $(document).outerHeight() - tipOffset.top - $(tip).outerHeight()
      tipOffset.top = tipOffset.top + offsetBottom if offsetBottom < 0
      offsetRight = $("html").outerWidth() - tipOffset.left - $(tip).outerWidth()
      tipOffset.left = tipOffset.left + offsetRight if offsetRight < 0

      tipOffset.top = 0 if tipOffset.top < 0
      tipOffset.left = 0 if tipOffset.left < 0

      tip.offset(tipOffset)

      # reposition the arrow
      if step.placement == 'bottom' or step.placement == 'top'
        @_replaceArrow(tip, (tipOffset.left-original_left)*2, original_offsetWidth, 'left') if original_left != tipOffset.left
      else
        @_replaceArrow(tip, (tipOffset.top-original_top)*2, original_offsetHeight, 'top') if original_top != tipOffset.top

    # copy pasted from bootstrap-tooltip.js
    # with some alterations
    _replaceArrow: (tip, delta, dimension, position)->
      tip
        .find(".arrow")
        .css(position, if delta then (50 * (1 - delta / dimension) + "%") else '')

    # Scroll to the popup if it is not in the viewport
    _scrollIntoView: (tip) ->
      tipRect = tip.get(0).getBoundingClientRect()
      unless tipRect.top >= 0 && tipRect.bottom < $(window).height() && tipRect.left >= 0 && tipRect.right < $(window).width()
        tip.get(0).scrollIntoView(true)

    # Debounced window resize
    _onResize: (callback, timeout) ->
      $(window).on "resize.tour.#{@_options.name}", ->
        clearTimeout(timeout)
        timeout = setTimeout(callback, 100)

    # Keyboard navigation
    _setupKeyboardNavigation: ->
      if @_options.keyboard
        $(document).on "keyup.tour.#{@_options.name}", (e) =>
          return unless e.which
          switch e.which
            when 39
              e.preventDefault()
              if @_current < @_steps.length - 1
                @next()
              else
                @end()
            when 37
              e.preventDefault()
              if @_current > 0
                @prev()
            when 27
              e.preventDefault()
              @end()

    # Checks if the result of a callback is a promise
    _makePromise: (result) ->
      if result && $.isFunction(result.then) then result else null

    _callOnPromiseDone: (promise, cb, arg) ->
      if promise
        promise.then (e) =>
          cb.call(@, arg)
      else
        cb.call(@, arg)

    _showBackdrop: (el) ->
      return unless @backdrop.overlay == null

      @_showOverlay()
      @_showOverlayElement(el)

    _hideBackdrop: ->
      return if @backdrop.overlay == null

      @_hideOverlayElement()
      @_hideOverlay()

    _showOverlay: ->
      @backdrop = $('<div/>')
      @backdrop.addClass('tour-backdrop')
      @backdrop.height $(document).innerHeight()

      $('body').append @backdrop

    _hideOverlay: ->
      @backdrop.remove()
      @backdrop.overlay = null

    _showOverlayElement: (el) ->
      step = $(el)

      offset = step.offset()
      offset.top = offset.top
      offset.left = offset.left

      background = $('<div/>')
      background
        .width(step.innerWidth())
        .height(step.innerHeight())
        .addClass('tour-step-background')
        .offset(offset)

      step.addClass('tour-step-backdrop')

      $('body').append background
      @backdrop.step = step
      @backdrop.background = background

    _hideOverlayElement: ->
      @backdrop.step.removeClass('tour-step-backdrop')

      @backdrop.background.remove()
      @backdrop.step = null
      @backdrop.background = null

  window.Tour = Tour

)(jQuery, window)

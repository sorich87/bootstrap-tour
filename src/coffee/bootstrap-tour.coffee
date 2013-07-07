(($, window) ->
  document = window.document

  class Tour
    constructor: (options) ->
      @_options = $.extend({
        name: 'tour'
        container: 'body'
        keyboard: true
        useLocalStorage: false
        debug: false
        backdrop: false
        redirect: true
        basePath: ''
        template: "<div class='popover tour'>
          <div class='arrow'></div>
          <h3 class='popover-title'></h3>
          <div class='popover-content'></div>
          <div class='popover-navigation'>
            <button class='btn' data-role='prev'>&laquo; Prev</button>
            <span data-role='separator'>|</span>
            <button class='btn' data-role='next'>Next &raquo;</button>
            <button class='btn' data-role='end'>End tour</button>
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
      }, options)

      # validation
      if ! @_options.useLocalStorage and ! $.cookie
        @_debug "jQuery.cookie is not loaded."

      @_steps = []
      @setCurrentStep()
      @backdrop = {
        overlay: null
        step: null
        background: null
      }

    # Set a state in localstorage or cookies. Setting to null deletes the state
    setState: (key, value) ->
      key = "#{@_options.name}_#{key}"
      if this._options.useLocalStorage
        window.localStorage.setItem(key, value)
      else
        $.cookie(key, value, { expires: 36500, path: '/' })
      @_options.afterSetState(key, value)

    # Remove the current state from the storage layer
    removeState: (key) ->
      key = "#{@_options.name}_#{key}"
      if this._options.useLocalStorage
        window.localStorage.removeItem(key)
      else
        $.removeCookie(key, { path: '/' })
      @_options.afterRemoveState(key)

    # Get the current state from the storage layer
    getState: (key) ->
      if this._options.useLocalStorage
        value = window.localStorage.getItem("#{@_options.name}_#{key}")
      else
        value = $.cookie("#{@_options.name}_#{key}")

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
        template: @_options.template
        onShow: @_options.onShow
        onShown: @_options.onShown
        onHide: @_options.onHide
        onHidden: @_options.onHidden
        onNext: @_options.onNext
        onPrev: @_options.onPrev
      }, @_steps[i]) if @_steps[i]?

    # Start tour from current step
    start: (force = false) ->
      return @_debug "Tour ended, start prevented." if @ended() && !force

      # Go to next step after click on element with attribute 'data-role=next'
      $(document).off("click.bootstrap-tour",".popover *[data-role=next]").on "click.bootstrap-tour", ".popover *[data-role=next]", (e) =>
        e.preventDefault()
        @next()

      # Go to previous step after click on element with attribute 'data-role=prev'
      $(document).off("click.bootstrap-tour",".popover *[data-role=prev]").on "click.bootstrap-tour", ".popover *[data-role=prev]", (e) =>
        e.preventDefault()
        @prev()

      # End tour after click on element with attribute 'data-role=end'
      $(document).off("click.bootstrap-tour",".popover *[data-role=end]").on "click.bootstrap-tour", ".popover *[data-role=end]", (e) =>
        e.preventDefault()
        @end()

      # Reshow popover on window resize using debounced resize
      @_onresize(=> @showStep(@_current))

      @_setupKeyboardNavigation()

      promise = @_makePromise(@_options.onStart(@) if @_options.onStart?)
      @_callOnPromiseDone(promise, @showStep, @_current)

    # Hide current step and show next step
    next: ->
      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, @showNextStep)

    # Hide current step and show prev step
    prev: ->
      promise = @hideStep(@_current)
      @_callOnPromiseDone(promise, @showPrevStep)

    # End tour
    end: ->
      endHelper = (e) =>
        $(document).off "click.bootstrap-tour"
        $(document).off "keyup.bootstrap-tour"
        $(window).off "resize.bootstrap-tour"
        @setState("end", "yes")
        @_hideBackdrop()

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
      promise = @_makePromise (step.onHide(@) if step.onHide?)

      hideStepHelper = (e) =>
        $element = $(step.element).popover("hide")
        $element.css("cursor", "").off "click.bootstrap-tour" if step.reflex
        @_hideBackdrop() if step.backdrop

        step.onHidden(@) if step.onHidden?

      @_callOnPromiseDone(promise, hideStepHelper)

      promise

    # Show the specified step
    showStep: (i) ->
      step = @getStep(i)
      return unless step

      # If onShow returns a promise, lets wait until it's done to execute
      promise = @_makePromise (step.onShow(@) if step.onShow?)

      showStepHelper = (e) =>
        @setCurrentStep(i)

        # Support string or function for path
        path = if $.isFunction(step.path) then step.path.call() else @_options.basePath + step.path

        # Redirect to step path if not already there
        current_path = [document.location.pathname, document.location.hash].join('')
        if @_isRedirect(path, current_path)
          @_redirect(step, path)
          return

        # If step element is hidden, skip step
        unless step.element? && $(step.element).length != 0 && $(step.element).is(":visible")
          @_debug "Skip the step #{@_current + 1}. The element does not exist or is not visible."
          @showNextStep()
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
    showNextStep: ->
      step = @getStep(@_current)
      showNextStepHelper = (e) => @showStep(step.next)

      promise = @_makePromise (step.onNext(@) if step.onNext?)
      @_callOnPromiseDone(promise, showNextStepHelper)

    # Show prev step
    showPrevStep: ->
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

    # Render navigation
    _renderNavigation: (step, i, options) ->
      if $.isFunction(step.template)
        template = $(step.template(i, step))
      else template = $(step.template)

      template.find(".popover-navigation *[data-role=prev]").remove() unless step.prev >= 0
      template.find(".popover-navigation *[data-role=next]").remove() unless step.next >= 0
      template.find(".popover-navigation *[data-role=separator]").remove() unless step.prev >=0 and step.next >= 0

      # return the outerHTML of the jQuery el
      template.clone().wrap("<div>").parent().html()

    # Show step popover
    _showPopover: (step, i) ->
      options = $.extend {}, @_options

      if step.options
        $.extend options, step.options
      if step.reflex
        $(step.element).css("cursor", "pointer").on "click.bootstrap-tour", (e) =>
          @next()

      rendered = @_renderNavigation(step, i, options)

      $element = $(step.element)

      $element.popover('destroy') if $element.data('popover')

      $element.popover({
        placement: step.placement
        trigger: "manual"
        title: step.title
        content: step.content
        html: true
        animation: step.animation
        container: step.container
        template: rendered
        selector: step.element
      }).popover("show")

      $tip = $(step.element).data("popover").tip()
      $tip.attr("id", step.id)
      @_reposition($tip, step)
      @_scrollIntoView($tip)

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
    _onresize: (cb, timeout) ->
      $(window).on "resize.bootstrap-tour", ->
        clearTimeout(timeout)
        timeout = setTimeout(cb, 100)

    # Keyboard navigation
    _setupKeyboardNavigation: ->
      if @_options.keyboard
        $(document).on "keyup.bootstrap-tour", (e) =>
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
      if result && $.isFunction(result.then)
        return result
      else
        return null

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

      padding = 5

      offset = step.offset()
      offset.top = offset.top - padding
      offset.left = offset.left - padding

      background = $('<div/>')
      background
        .width(step.innerWidth() + padding)
        .height(step.innerHeight() + padding)
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

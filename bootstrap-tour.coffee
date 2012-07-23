### ============================================================
# bootstrap-tour.js v0.1
# http://pushly.github.com/bootstrap-tour/
# ==============================================================
# Copyright 2012 Push.ly
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

(($, window) ->
  document = window.document

  class Tour
    constructor: (options) ->
      @_options = $.extend({
        name: 'tour'
        end: 'End tour'
        next: 'Next &raquo;'
        previous: '&laquo; Prev'
        afterSetState: (key, value) ->
        afterGetState: (key, value) ->
        onShow: (tour) ->
        onHide: (tour) ->
      }, options)

      @_steps = []
      @setCurrentStep()

      # Go to next step after click on element with class .next
      $(document).on "click", ".popover .next", (e) =>
        e.preventDefault()
        @next()

      # Go to previous step after click on element with class .prev
      $(document).on "click", ".popover .prev", (e) =>
        e.preventDefault()
        @prev()

      # End tour after click on element with class .end
      $(document).on "click", ".popover .end", (e) =>
        e.preventDefault()
        @end()

    setState: (key, value) ->
      $.cookie("#{@_options.name}_#{key}", value, { expires: 36500, path: '/' })
      @_options.afterSetState(key, value)

    getState: (key) ->
      value = $.cookie("#{@_options.name}_#{key}")
      @_options.afterGetState(key, value)
      return value

    # Add a new step
    addStep: (step) ->
      @_steps.push step

    # Get a step by its indice
    getStep: (i) ->
      $.extend({
        path: ""
        placement: "right"
        title: ""
        content: ""
        next: if i == @_steps.length - 1 then -1 else i + 1
        prev: i - 1
        animation: true
        onShow: @_options.onShow
        onHide: @_options.onHide
      }, @_steps[i]) if @_steps[i]?

    # Start tour from current step
    start: (force = false) ->
      if force || ! @ended()
        @showStep(@_current)

    # Hide current step and show next step
    next: ->
      @hideStep(@_current)
      @showNextStep()

    # Hide current step and show prev step
    prev: ->
      @hideStep(@_current)
      @showPrevStep()

    # End tour
    end: ->
      @hideStep(@_current)
      @setState("end", "yes")

    # Verify if tour is enabled
    ended: ->
      !!@getState("end")

    # Restart tour
    restart: ->
      @setState("current_step", null)
      @setState("end", null)
      @setCurrentStep(0)
      @start()

    # Hide the specified step
    hideStep: (i) ->
      step = @getStep(i)
      step.onHide(@) if step.onHide?

      $(step.element).popover("hide")

    # Show the specified step
    showStep: (i) ->
      step = @getStep(i)

      return unless step

      @setCurrentStep(i)

      # Redirect to step path if not already there
      # Compare to path, then filename
      if step.path != "" && document.location.pathname != step.path && document.location.pathname.replace(/^.*[\\\/]/, '') != step.path
        document.location.href = step.path
        return

      step.onShow(@) if step.onShow?

      # If step element is hidden, skip step
      unless step.element? && $(step.element).length != 0 && $(step.element).is(":visible")
        @showNextStep()
        return

      # Show popover
      @_showPopover(step, i)

    # Setup current step variable
    setCurrentStep: (value) ->
      if value?
        @_current = value
        @setState("current_step", value)
      else
        @_current = @getState("current_step")
        if (@_current == null || @_current == "null")
          @_current = 0
        else
          @_current = parseInt(@_current)

    # Show next step
    showNextStep: ->
      step = @getStep(@_current)
      @showStep(step.next)

    # Show prev step
    showPrevStep: ->
      step = @getStep(@_current)
      @showStep(step.prev)

    # Show step popover
    _showPopover: (step, i) ->
      content = "#{step.content}<br /><p>"

      nav = []
      if step.prev >= 0
        nav.push "<a href='##{step.prev}' class='prev'>#{@_options.previous}</a>"
      if step.next >= 0
        nav.push "<a href='##{step.next}' class='next'>#{@_options.next}</a>"
      content += nav.join(" | ")

      content += "<a href='#' class='pull-right end'>#{@_options.end}</a>"

      $(step.element).popover({
        placement: step.placement
        trigger: "manual"
        title: step.title
        content: content
        animation: step.animation
      }).popover("show")

      tip = $(step.element).data("popover").tip()
      @_reposition(tip)
      @_scrollIntoView(tip)

    # Prevent popups from crossing over the edge of the window
    _reposition: (tip) ->
      tipOffset = tip.offset()
      offsetBottom = $(document).outerHeight() - tipOffset.top - $(tip).outerHeight()
      tipOffset.top = tipOffset.top + offsetBottom if offsetBottom < 0
      offsetRight = $(document).outerWidth() - tipOffset.left - $(tip).outerWidth()
      tipOffset.left = tipOffset.left + offsetRight if offsetRight < 0

      tipOffset.top = 0 if tipOffset.top < 0
      tipOffset.left = 0 if tipOffset.left < 0
      tip.offset(tipOffset)

    # Scroll to the popup if it is not in the viewport
    _scrollIntoView: (tip) ->
      tipRect = tip.get(0).getBoundingClientRect()
      unless tipRect.top > 0 && tipRect.bottom < $(window).height() && tipRect.left > 0 && tipRect.right < $(window).width()
        tip.get(0).scrollIntoView(true)

  window.Tour = Tour

)(jQuery, window)

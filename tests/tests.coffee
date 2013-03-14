module("bootstrap-tour",
  teardown: ->
    @tour.setState("current_step", null)
    @tour.setState("end", null)
    $.each(@tour._steps, (i, s) ->
      if s.element? && s.element.popover?
        s.element.popover("hide").removeData("popover")
    )
)

test "Tour should set the tour options", ->
  @tour = new Tour({
    name: "test"
    afterSetState: ->
      true
    afterGetState: ->
      true
  })
  equal(@tour._options.name, "test", "options.name is set")
  ok(@tour._options.afterGetState, "options.afterGetState is set")
  ok(@tour._options.afterSetState, "options.afterSetState is set")

test "Tour should have default name of 'tour'", ->
  @tour = new Tour()
  equal(@tour._options.name, "tour", "tour default name is 'tour'")

test "Tour should accept an array of steps and set the current step", ->
  @tour = new Tour()
  deepEqual(@tour._steps, [], "tour accepts an array of steps")
  strictEqual(@tour._current, 0, "tour initializes current step")

test "Tour.setState should save state cookie", ->
  @tour = new Tour()
  @tour.setState("test", "yes")
  strictEqual($.cookie("tour_test"), "yes", "tour saves state cookie")

test "Tour.getState should get state cookie", ->
  @tour = new Tour()
  @tour.setState("test", "yes")
  strictEqual(@tour.getState("test"), "yes", "tour gets state cookie")
  $.cookie("tour_test", null)

test "Tour.setState should save state localStorage items", ->
  @tour = new Tour({
    useLocalStorage: true
  })
  @tour.setState("test", "yes")
  strictEqual(window.localStorage.getItem("tour_test"), "yes", "tour save state localStorage items")

test "Tour.getState should get state localStorage items", ->
  @tour = new Tour({
    useLocalStorage: true
  })
  @tour.setState("test", "yes")
  strictEqual(@tour.getState("test"), "yes", "tour save state localStorage items")
  window.localStorage.setItem("tour_test", null)

test "Tour.addStep should add a step", ->
  @tour = new Tour()
  step = { element: $("<div></div>").appendTo("#qunit-fixture") }
  @tour.addStep(step)
  deepEqual(@tour._steps, [step], "tour adds steps")

test "Tour with onStart option should run the callback before showing the first step", ->
  tour_test = 0
  @tour = new Tour({
    onStart: ->
      tour_test += 2
  })
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual(tour_test, 2, "tour runs onStart when the first step shown")

test "Tour with onEnd option should run the callback after hiding the last step", ->
  tour_test = 0
  @tour = new Tour({
    onEnd: ->
      tour_test += 2
  })
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.end()
  strictEqual(tour_test, 2, "tour runs onEnd when the last step hidden")

test "Tour with onShow option should run the callback before showing the step", ->
  tour_test = 0
  @tour = new Tour({
    onShow: ->
      tour_test += 2
  })
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual(tour_test, 2, "tour runs onShow when first step shown")
  @tour.next()
  strictEqual(tour_test, 4, "tour runs onShow when next step shown")

test "Tour with onShown option should run the callback after showing the step", ->
  tour_test = 0
  @tour = new Tour({
    onShown: ->
      tour_test += 2
  })
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual(tour_test, 2, "tour runs onShown after first step shown")

test "Tour with onHide option should run the callback before hiding the step", ->
  tour_test = 0
  @tour = new Tour({
    onHide: ->
      tour_test += 2
  })
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.next()
  strictEqual(tour_test, 2, "tour runs onHide when first step hidden")
  @tour.hideStep(1)
  strictEqual(tour_test, 4, "tour runs onHide when next step hidden")

test "Tour.addStep with onShow option should run the callback before showing the step", ->
  tour_test = 0
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
    onShow: ->
      tour_test = 2 })
  @tour.start()
  strictEqual(tour_test, 0, "tour does not run onShow when step not shown")
  @tour.next()
  strictEqual(tour_test, 2, "tour runs onShow when step shown")

test "Tour.addStep with onHide option should run the callback before hiding the step", ->
  tour_test = 0
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({
    element: $("<div></div>").appendTo("#qunit-fixture")
    onHide: ->
      tour_test = 2
  })
  @tour.start()
  @tour.next()
  strictEqual(tour_test, 0, "tour does not run onHide when step not hidden")
  @tour.hideStep(1)
  strictEqual(tour_test, 2, "tour runs onHide when step hidden")

test "Tour.getStep should get a step", ->
  @tour = new Tour()
  step = {
    element: $("<div></div>").appendTo("#qunit-fixture")
    path: "test"
    placement: "left"
    title: "Test"
    content: "Just a test"
    prev: -1
    next: 2
    end: false
    animation: false
    onShow: (tour) ->
    onHide: (tour) ->
    onShown: (tour) ->
  }
  @tour.addStep(step)
  deepEqual(@tour.getStep(0), step, "tour gets a step")

test "Tour.start should start a tour", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual($(".popover").length, 1, "tour starts")

test "Tour.start should not start a tour that ended", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.setState("end", "yes")
  @tour.start()
  strictEqual($(".popover").length, 0, "previously ended tour don't start again")

test "Tour.start(true) should force starting a tour that ended", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.setState("end", "yes")
  @tour.start(true)
  strictEqual($(".popover").length, 1, "previously ended tour starts again if forced to")

test "Tour.next should hide current step and show next step", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.next()
  strictEqual(@tour.getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides current step")
  strictEqual(@tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows next step")

test "Tour.end should hide current step and set end state", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.end()
  strictEqual(@tour.getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides current step")
  strictEqual(@tour.getState("end"), "yes", "tour sets end state")

test "Tour.ended should return true is tour ended and false if not", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual(@tour.ended(), false, "tour returns false if not ended")
  @tour.end()
  strictEqual(@tour.ended(), true, "tour returns true if ended")

test "Tour.restart should clear all states and start tour", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.next()
  @tour.end()
  @tour.restart()
  strictEqual(@tour.getState("end"), null, "tour sets end state")
  strictEqual(@tour._current, 0, "tour sets first step")
  strictEqual($(".popover").length, 1, "tour starts")

test "Tour.hideStep should hide a step", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.hideStep(0)
  strictEqual(@tour.getStep(0).element.data("popover").tip().filter(":visible").length, 0, "tour hides step")

test "Tour.showStep should set a step and show it", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.showStep(1)
  strictEqual(@tour._current, 1, "tour sets step")
  strictEqual($(".popover").length, 1, "tour shows one step")
  strictEqual(@tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows correct step")

test "Tour.showStep should not show anything when the step doesn't exist", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.showStep(2)
  strictEqual($(".popover").length, 0, "tour doesn't show any step")

test "Tour.showStep should skip step when no element is specified", ->
  @tour = new Tour()
  @tour.addStep({})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.showStep(1)
  strictEqual(@tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element")

test "Tour.showStep should skip step when element doesn't exist", ->
  @tour = new Tour()
  @tour.addStep({element: "#tour-test"})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.showStep(1)
  strictEqual(@tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element")

test "Tour.showStep should skip step when element is invisible", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture").hide()})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.showStep(1)
  strictEqual(@tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour skips step with no element")

test "Tour.setCurrentStep should set the current step", ->
  @tour = new Tour()
  @tour.setCurrentStep(4)
  strictEqual(@tour._current, 4, "tour sets current step if passed a value")
  @tour.setState("current_step", 2)
  @tour.setCurrentStep()
  strictEqual(@tour._current, 2, "tour reads current step state if not passed a value")

test "Tour.showNextStep should show the next step", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.showNextStep()
  strictEqual(@tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour shows next step")

test "Tour.showPrevStep should show the previous step", ->
  @tour = new Tour()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.showStep(1)
  @tour.showPrevStep()
  strictEqual(@tour.getStep(0).element.data("popover").tip().filter(":visible").length, 1, "tour shows previous step")

test "Tour.showStep should show multiple step on the same element", ->
  element = $("<div></div>").appendTo("#qunit-fixture")
  @tour = new Tour()
  @tour.addStep({element: element})
  @tour.addStep({element: element})
  @tour.start()
  strictEqual(@tour.getStep(0).element.data("popover").tip().filter(":visible").length, 1, "tour show the first step")
  @tour.showNextStep()
  strictEqual(@tour.getStep(1).element.data("popover").tip().filter(":visible").length, 1, "tour show the second step on the same element")

test "Tour properly verify paths", ->
  @tour = new Tour()

  strictEqual(@tour._redirect(undefined, "/"), false, "don't redirect if no path")
  strictEqual(@tour._redirect("", "/"), false, "don't redirect if path empty")
  strictEqual(@tour._redirect("/somepath", "/somepath"), false, "don't redirect if path matches current path")
  strictEqual(@tour._redirect("/somepath/", "/somepath"), false, "don't redirect if path with slash matches current path")
  strictEqual(@tour._redirect("/somepath", "/somepath/"), false, "don't redirect if path matches current path with slash")
  strictEqual(@tour._redirect("/somepath?search=true", "/somepath"), false, "don't redirect if path with query params matches current path")
  strictEqual(@tour._redirect("/somepath/?search=true", "/somepath"), false, "don't redirect if path with slash and query params matches current path")
  strictEqual(@tour._redirect("/anotherpath", "/somepath"), true, "redirect if path doesn't match current path")

test "Tour.getState should return null after Tour.removeState with null value using cookies", ->
  @tour = new Tour({useLocalStorage: false})
  @tour.setState("test", "test")
  @tour.removeState("test")
  strictEqual(@tour.getState("test"), null, "tour returns null after null setState")

test "Tour.getState should return null after Tour.removeState with null value using localStorage", ->
  @tour = new Tour({useLocalStorage: true})
  @tour.setState("test", "test")
  @tour.removeState("test")
  strictEqual(@tour.getState("test"), null, "tour returns null after null setState")

test "Tour.removeState should call afterRemoveState callback", ->
  sentinel = false
  @tour = new Tour({afterRemoveState: -> sentinel = true})
  @tour.removeState("current_step")
  strictEqual(sentinel, true, "removeState calls callback")

test "Tour shouldn't move to the next state until the onShow promise is resolved", ->
  @tour = new Tour()
  deferred = $.Deferred()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture"), onShow: -> return deferred})
  @tour.start()
  @tour.next()
  strictEqual(@tour._current, 0, "tour shows old state until resolving of onShow promise")
  deferred.resolve()
  strictEqual(@tour._current, 1, "tour shows new state after resolving onShow promise")

test "Tour shouldn't hide popover until the onHide promise is resolved", ->
  @tour = new Tour()
  deferred = $.Deferred()
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture"), onHide: -> return deferred})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  @tour.next()
  strictEqual(@tour._current, 0, "tour shows old state until resolving of onHide promise")
  deferred.resolve()
  strictEqual(@tour._current, 1, "tour shows new state after resolving onShow promise")

test "Tour shouldn't start until the onStart promise is resolved", ->
  deferred = $.Deferred()
  @tour = new Tour({onStart: -> return deferred})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  @tour.start()
  strictEqual($(".popover").length, 0, "Tour does not start before onStart promise is resolved")
  deferred.resolve()
  strictEqual($(".popover").length, 1, "Tour starts after onStart promise is resolved")

test "Reflex parameter should change the element cursor to pointer when the step is displayed", ->
  $element = $("<div></div>").appendTo("#qunit-fixture")
  @tour = new Tour()
  @tour.addStep({element: $element, reflex: true})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  strictEqual($element.css("cursor"), "auto", "Tour doesn't change the element cursor before displaying the step")
  @tour.start()
  strictEqual($element.css("cursor"), "pointer", "Tour change the element cursor to pointer when the step is displayed")
  @tour.next()
  strictEqual($element.css("cursor"), "auto", "Tour reset the element cursor when the step is hidden")

test "Reflex parameter should change the element cursor to pointer when the step is displayed", ->
  $element = $("<div></div>").appendTo("#qunit-fixture")
  @tour = new Tour()
  @tour.addStep({element: $element, reflex: true})
  @tour.addStep({element: $("<div></div>").appendTo("#qunit-fixture")})
  strictEqual($element.css("cursor"), "auto", "Tour doesn't change the element cursor before displaying the step")
  @tour.start()
  strictEqual($element.css("cursor"), "pointer", "Tour change the element cursor to pointer when the step is displayed")
  @tour.next()
  strictEqual($element.css("cursor"), "auto", "Tour reset the element cursor when the step is hidden")


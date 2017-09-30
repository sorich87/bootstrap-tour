describe 'Bootstrap Tour', ->

  beforeEach ->
    $.support.transition = false
    $.fx.off = true

  afterEach ->
    tour = @tour
    @tour._setState('current_step', null)
    @tour._setState('end', null)
    $.each @tour._options.steps, (i, s) ->
      $element = $(tour.getStep(i).element)

      $element
      .popover('destroy')
      .removeData('bs.popover')
      $element.remove()

  it 'should set the tour options', ->
    @tour = new Tour
      name: 'test'
      afterSetState: -> true
      afterGetState: -> true
    expect(@tour._options.name).toBe 'test'
    expect(@tour._options.afterGetState).toBeTruthy
    expect(@tour._options.afterSetState).toBeTruthy

  it 'should have `tour` as default name', ->
    @tour = new Tour
    expect(@tour._options.name).toBe 'tour'

  it 'should accept an array of steps', ->
    @tour = new Tour
    expect(@tour._options.steps).toEqual [] # tour accepts an array of steps

  it '`_setState` should save state as localStorage item', ->
    @tour = new Tour
    @tour._setState('test', 'yes')
    expect(window.localStorage.getItem('tour_test')).toBe 'yes'

  it '`_setState` should execute storage.setItem function if provided', ->
    aliasKeyName = undefined
    aliasValue = undefined

    @tour = new Tour
      name: 'test'
      storage:
        setItem: (keyName, value) ->
          aliasKeyName = keyName
          aliasValue = value
        getItem: (value) ->
          return aliasValue

    @tour._setState('save', 'yes')
    expect(aliasKeyName).toBe 'test_save'
    expect(aliasValue).toBe 'yes'

  it '`_setState` should save state internally if storage is false', ->
    @tour = new Tour
      storage: false
    @tour._setState('test', 'yes')
    expect(@tour._state['test']).toBe 'yes'

  it '`_removeState` should remove state localStorage item', ->
    @tour = new Tour
    @tour._setState('test', 'yes')
    @tour._removeState('test')
    expect(window.localStorage.getItem('tour_test')).toBe null

  it '`_removeState` should remove state internally if storage is false', ->
    @tour = new Tour
      storage: false
    @tour._setState('test', 'yes')
    @tour._removeState('test')
    expect(@tour._state['test']).toBeUndefined()

  it '`_getState` should get state localStorage items', ->
    @tour = new Tour
    @tour._setState('test', 'yes')
    expect(@tour._getState('test')).toBe 'yes'
    window.localStorage.setItem('tour_test', null)

  it '`_getState` should get the internal state if storage is false', ->
    @tour = new Tour
      storage: false
    @tour._setState('test', 'yes')
    expect(@tour._getState('test')).toBe 'yes'

  it '`addStep` should add a step', ->
    @tour = new Tour
    step = element: $('<div></div>').appendTo('body')
    @tour.addStep(step)
    expect(@tour._options.steps).toEqual [step]

  it '`addSteps` should add multiple step', ->
    @tour = new Tour
    firstStep = element: $('<div></div>').appendTo('body')
    secondStep = element: $('<div></div>').appendTo('body')
    @tour.addSteps([firstStep, secondStep])
    expect(@tour._options.steps).toEqual [firstStep, secondStep]

  it 'step should have an id', ->
    @tour = new Tour
    $element = $('<div></div>').appendTo('body')
    @tour.addStep({element: $element})
    @tour.start()
    expect($element.data('bs.popover').tip().attr('id')).toBe 'step-0' # tour runs onStart when the first step shown

  it 'with `onStart` option should run the callback before showing the first step', ->
    tour_test = 0
    @tour = new Tour
      onStart: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect(tour_test).toBe 2 # tour runs onStart when the first step shown

  it 'with `onEnd` option should run the callback after hiding the last step', ->
    tour_test = 0
    @tour = new Tour
      onEnd: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.end()
    expect(tour_test).toBe 2 # tour runs onEnd when the last step hidden

  it 'with `onShow` option should run the callback before showing the step', ->
    tour_test = 0
    @tour = new Tour
      onShow: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect(tour_test).toBe 2 # tour runs onShow when first step shown
    @tour.next()
    expect(tour_test).toBe 4 # tour runs onShow when next step shown

  it 'with `onShown` option should run the callback after showing the step', ->
    tour_test = 0
    @tour = new Tour
      onShown: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect(tour_test).toBe 2 # tour runs onShown after first step shown


  it 'with `onHide` option should run the callback before hiding the step', ->
    tour_test = 0
    @tour = new Tour
      onHide: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect(tour_test).toBe 2 # tour runs onHide when first step hidden
    @tour.hideStep(1)
    expect(tour_test).toBe 4 # tour runs onHide when next step hidden

  it 'with onHidden option should run the callback after hiding the step', ->
    tour_test = 0
    @tour = new Tour
      onHidden: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect(tour_test).toBe 2 # tour runs onHidden after first step hidden
    @tour.next()
    expect(tour_test).toBe 4 # tour runs onHidden after next step hidden

  it '`addStep` with onShow option should run the callback before showing the step', ->
    tour_test = 0
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      onShow: -> tour_test = 2
    @tour.start()
    expect(tour_test).toBe 0 # tour does not run onShow when step not shown
    @tour.next()
    expect(tour_test).toBe 2 # tour runs onShow when step shown

  it '`addStep` with onHide option should run the callback before hiding the step', ->
    tour_test = 0
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      onHide: -> tour_test = 2
    @tour.start()
    @tour.next()
    expect(tour_test).toBe 0 # tour does not run onHide when step not hidden
    @tour.hideStep(1)
    expect(tour_test).toBe 2 # tour runs onHide when step hidden

  it '`getStep` should get a step', ->
    @tour = new Tour
    step =
      element: $('<div></div>').appendTo('body')
      id: 'step-0'
      path: 'test'
      host: ''
      placement: 'left'
      title: 'Test'
      content: 'Just a test'
      next: 2
      prev: -1
      animation: false
      autoscroll: true
      container: 'body'
      backdrop: false
      backdropPadding: 0
      backdropContainer: 'body'
      backdropElement: $('<div></div>').appendTo('body')
      redirect: true
      reflexElement: $('<div></div>').appendTo('body')
      orphan: false
      duration: false
      delay: false
      template: '<div class="popover">
        <div class="arrow"></div>
        <h3 class="popover-title"></h3>
        <div class="popover-content"></div>
        <nav class="popover-navigation">
          <div class="btn-group">
            <button class="btn btn-sm btn-default" data-role="prev">&laquo; Prev</button>
            <button class="btn btn-sm btn-default" data-role="next">Next &raquo;</button>
          </div>
          <button class="btn btn-sm btn-default" data-role="end">End tour</button>
        </nav>
      </div>'
      onShow: (tour) ->
      onShown: (tour) ->
      onHide: (tour) ->
      onHidden: (tour) ->
      onNext: (tour) ->
      onPrev: (tour) ->
      onPause: (tour) ->
      onResume: (tour) ->
      onRedirectError: (tour) ->
    @tour.addStep(step)
    # remove properties that we don't want to check from both steps object
    expect(@tour.getStep(0)).toEqual step

  it '`start` should start a tour', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect($('.popover').length).toBe 1

  it '`init` should continue a tour', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour._setState('current_step', 0)
    @tour.init()
    expect($('.popover').length).toBe 1

  it '`init` should not continue a tour that ended', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour._setState('current_step', 0)
    @tour._setState('end', 'yes')
    @tour.init()
    expect($('.popover').length).toBe 0 # previously ended tour don't start again

  it '`init`(true) should force continuing a tour that ended', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour._setState('current_step', 0)
    @tour._setState('end', 'yes')
    @tour.init(true)
    expect($('.popover').length).toBe 1 # previously ended tour starts again if forced to

  it '`next` should hide current step and show next step', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect(@tour.getStep(0).element.data('bs.popover')).toBeUndefined() # tour hides current step
    expect(@tour.getStep(1).element.data('bs.popover').tip().filter(':visible').length).toBe 1 # tour shows next step

  it '`end` should hide current step and set end state', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.end()
    expect(@tour.getStep(0).element.data('bs.popover')).toBeUndefined() # tour hides current step
    expect(@tour._getState('end')).toBe 'yes'

  it '`ended` should return true if tour ended and false if not', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect(@tour.ended()).toBe false
    @tour.end()
    expect(@tour.ended()).toBe true

  it '`ended` should always return false if tour started by force', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.end()
    @tour.start(true)
    expect(@tour.ended()).toBe false

  it '`restart` should clear all states and start tour', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    @tour.end()
    @tour.restart()
    expect(@tour._getState('end')).toBe null
    expect(@tour._current).toBe 0
    expect($('.popover').length).toBe 1 # tour starts

  it '`hideStep` should hide a step', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.hideStep(0)
    expect(@tour.getStep(0).element.data('bs.popover')).toBeUndefined()

  it '`showStep` should set a step and show it', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.showStep(1)
    expect(@tour._current).toBe 1
    expect($('.popover').length).toBe 1 # tour shows one step
    expect(@tour.getStep(1).element.data('bs.popover').tip().filter(':visible').length).toBe 1 # tour shows correct step

  it '`showStep` should not show anything when the step does not exist', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.showStep(2)
    expect($('.popover').length).toBe 0

  it '`showStep` should execute template if it is a function', ->
    @tour = new Tour
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      template: -> '<div class="popover"></div>'
    @tour.showStep(0)
    expect($('.popover').length).toBe 1

  it '`getStep` should add disabled classes to the first and last popover buttons', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.showStep(0)
    expect($('.popover [data-role="prev"]').hasClass('disabled')).toBe true
    @tour.showStep(1)
    expect($('.popover [data-role="next"]').hasClass('disabled')).toBe true

  it '`setCurrentStep` should set the current step', ->
    @tour = new Tour
    @tour.setCurrentStep(4)
    expect(@tour._current).toBe 4 # tour sets current step if passed a value
    @tour._setState('current_step', 2)
    @tour.setCurrentStep()
    expect(@tour._current).toBe 2 # tour reads current step state if not passed a value

  it '`goTo` should show the specified step', ->
    @tour = new Tour
    @tour.addStep({element: $('<div></div>').appendTo('body')})
    @tour.addStep({element: $('<div></div>').appendTo('body')})
    @tour.goTo(1)
    expect(@tour.getStep(1).element.data('bs.popover').tip().filter(':visible').length).toBe 1

  it '`next` should show the next step', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect(@tour.getStep(1).element.data('bs.popover').tip().filter(':visible').length).toBe 1

  it '`prev` should show the previous step', ->
    @tour = new Tour
    @tour.addStep({element: $('<div></div>').appendTo('body')})
    @tour.addStep({element: $('<div></div>').appendTo('body')})
    @tour.goTo(1)
    @tour.prev()
    expect(@tour.getStep(0).element.data('bs.popover').tip().filter(':visible').length).toBe 1

  it '`showStep` should show multiple step on the same element', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()

    # tour show the first step
    expect(@tour.getStep(0).element.data('bs.popover').tip().filter(':visible').length).toBe 1
    @tour.next()

    # tour show the second step on the same element
    expect(@tour.getStep(1).element.data('bs.popover').tip().filter(':visible').length).toBe 1

  it 'should get url properties correctly', ->
    @tour = new Tour

    expect(@tour._getProtocol('http://example.com')).toBe 'http'
    expect(@tour._getProtocol('https://example.com')).toBe 'https'
    expect(@tour._getProtocol('www.example.com')).toBe 'http'
    expect(@tour._getProtocol('example.com')).toBe 'http'

    expect(@tour._getHost('http://example.com')).toBe 'example.com'
    expect(@tour._getHost('www.example.com')).toBe 'www.example.com'
    expect(@tour._getHost('example.com/path')).toBe 'example.com'

    expect(@tour._getPath('/somepath?foo=bar')).toBe '/somepath'
    expect(@tour._getPath('/somepath#foo=bar')).toBe '/somepath'
    expect(@tour._getPath('/somepath?foo=bar#hash')).toBe '/somepath'

    expect(@tour._getQuery('/somepath?one=bar')).toEqual {one: 'bar'}
    expect(@tour._getQuery('/somepath?one=bar&two=foo')).toEqual {one: 'bar', two: 'foo'}

    expect(@tour._getHash('/somepath#one=bar&two=foo')).toEqual {one: 'bar', two: 'foo'}
    expect(@tour._getHash('/somepath#one=bar&two=foo')).toEqual {one: 'bar', two: 'foo'}

  it 'should evaluate `path` correctly', ->
    @tour = new Tour

    # redirect if path doesn't match current path
    expect(
      @tour._isRedirect(
        '', '/anotherpath',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe true
    # don't redirect if no path
    expect(
      @tour._isRedirect(
        '', undefined,
        {
          origin: ''
          href: ''
          pathname: '/'
          search: ''
          hash: ''
        }
      )
    ).toBe false
    # don't redirect if path empty
    expect(
      @tour._isRedirect(
        '', '',
        {
          origin: ''
          href: ''
          pathname: '/'
          search: ''
          hash: ''
        }
      )
    ).toBe false
    # don't redirect if path matches current path
    expect(
      @tour._isRedirect(
        '', '/somepath',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe false
    # don't redirect if path with slash matches current path
    expect(
      @tour._isRedirect(
        '', '/somepath/',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe false
    # don't redirect if path matches current path with slash
    expect(
      @tour._isRedirect(
        '', '/somepath',
        {
          origin: ''
          href: ''
          pathname: '/somepath/'
          search: ''
          hash: ''
        }
      )
    ).toBe false
    # redirect if path with query params doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath?search=true',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe true
    # redirect if path with slash and query params doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath/?search=true',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe true

    # redirect if path with more than one query param doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath?search=true&foo=bar',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe true

    # redirect if path with and query params doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath?search=true&foo=bar',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: '?search=true'
          hash: ''
        }
      )
    ).toBe true

    # redirect if path query params number doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath?search=true&foo=bar',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: '?foo=bar'
          hash: ''
        }
      )
    ).toBe true

    # don't redirect if path with query params matches current path
    expect(
      @tour._isRedirect(
        '', '/somepath?search=true&foo=bar',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: '?foo=bar&search=true'
          hash: ''
        }
      )
    ).toBe false

    # don't redirect if path with query params matches current path
    expect(
      @tour._isRedirect(
        '', '/somepath?search=true&foo=bar'
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: '?search=true&foo=bar'
          hash:''
        }
      )
    ).toBe false

    # redirect if path with one hash param doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath#search=true',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe true

    # redirect if path with slash and one hash param doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath/#search=true',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe true

    # redirect if path with more than one hash params doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath#search=true&foo=bar',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: ''
        }
      )
    ).toBe true

    # redirect if path hash params number doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath#search=true&foo=bar',
        {
          origin: ''
          href: ''
          pathname: '/somepath'
          search: ''
          hash: '#search=true'
        }
      )
    ).toBe true

    # redirect if path hash params number doesn't matche current path
    expect(
      @tour._isRedirect(
        '', '/somepath#search=true&foo=bar',
        {
          origin: '',
          href: '',
          pathname: '/somepath',
          search: '',
          hash: '#foo=bar'
        }
      )
    ).toBe true

    # don't redirect if path with hash params matches current path
    expect(
      @tour._isRedirect(
        '', '/somepath#search=true&foo=bar',
        {
          origin: '',
          href: '',
          pathname: '/somepath',
          search: '',
          hash: '#foo=bar&search=true'
        }
      )
    ).toBe false

    # don't redirect if path with hash params matches current path
    expect(
      @tour._isRedirect(
        '', '/somepath#search=true&foo=bar',
        {
          origin: '',
          href: '',
          pathname: '/somepath',
          search: '',
          hash: '#search=true&foo=bar'
        }
      )
    ).toBe false

    # don't redirect if current path matches path regex
    expect(
      @tour._isRedirect(
        '', /some.*/,
        {
          origin: '',
          href: '',
          pathname: '/somepath',
          search: '',
          hash: ''
        }
      )
    ).toBe false

  it '`_getState` should return null after `_removeState` with null value', ->
    @tour = new Tour
    @tour._setState('test', 'test')
    @tour._removeState('test')
    expect(@tour._getState('test')).toBe null

  it '`_removeState` should call `afterRemoveState` callback', ->
    sentinel = false
    @tour = new Tour
      afterRemoveState: -> sentinel = true
    @tour._removeState('current_step')
    expect(sentinel).toBe true

  it 'should not move to the next state until the onShow promise is resolved', ->
    @tour = new Tour
    deferred = $.Deferred()
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      onShow: -> return deferred
    @tour.start()
    @tour.next()
    expect(@tour.getStep(0).element.data('bs.popover')).toBeUndefined
    deferred.resolve()
    expect(@tour.getStep(1).element.data('bs.popover').tip().filter(':visible').length).toBe 1

  it 'should not hide popover until the onHide promise is resolved', ->
    deferred = $.Deferred()
    @tour = new Tour
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      onHide: -> return deferred
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect(@tour._current).toBe 0 # tour shows old state until resolving of onHide promise
    deferred.resolve()
    expect(@tour._current).toBe 1 # tour shows new state after resolving onShow promise

  it 'should not start until the onStart promise is resolved', ->
    deferred = $.Deferred()
    @tour = new Tour
      onStart: -> deferred
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect($('.popover').length).toBe 0
    deferred.resolve()
    expect($('.popover').length).toBe 1

  it 'should add `tour-step-element-reflex` class to the step element if reflex is active', ->
    @tour = new Tour
    $element = $('<div></div>').appendTo('body')
    @tour.addStep
      element: $element
      reflex: true
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    expect($element.hasClass('tour-step-element-reflex')).toBe false
    @tour.start()
    expect($element.hasClass('tour-step-element-reflex')).toBe true
    @tour.next()
    expect($element.hasClass('tour-step-element-reflex')).toBe false

  it 'should add `tour-step-element-reflex` class to reflexElement if reflex is defined', ->
    @tour = new Tour
    $element = $('<div></div>').appendTo('body')
    $definedElement = $('<div id="ref"></div>').appendTo('body')
    @tour.addStep
      element: $element
      reflex: true
      reflexElement: '#ref'
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    expect($element.hasClass('tour-step-element-reflex')).toBe false
    expect($definedElement.hasClass('tour-step-element-reflex')).toBe false
    @tour.start()
    expect($element.hasClass('tour-step-element-reflex')).toBe false
    expect($definedElement.hasClass('tour-step-element-reflex')).toBe true
    @tour.next()
    expect($element.hasClass('tour-step-element-reflex')).toBe false
    expect($definedElement.hasClass('tour-step-element-reflex')).toBe false

  it 'should add `tour-{tourName}-reflex` class to the step popover if reflex is active', ->
    @tour = new Tour
    $element = $('<div></div>').appendTo('body')
    @tour.addStep
      element: $element
      reflex: true
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    expect($('.popover').hasClass("tour-#{@tour._options.name}-reflex")).toBe false
    @tour.start()
    expect($('.popover').hasClass("tour-#{@tour._options.name}-reflex")).toBe true
    @tour.next()
    expect($('.popover').hasClass("tour-#{@tour._options.name}-reflex")).toBe false

  it '`showStep` redirects to the anchor when the path is an anchor', ->
    @tour = new Tour
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      path: '#mytest'
    @tour.showStep(0)
    expect(document.location.hash).toBe '#mytest' # Tour step has moved to the anchor
    document.location.hash = ''

  it '`showStep` show the step when the path is an anchor', ->
    current_path = location.pathname
    @tour = new Tour
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      path: "#{current_path}#mytest"
    @tour.showStep(0)
    expect(@tour.getStep(0).element.data('bs.popover').tip().filter(':visible').length).toBe 1 # tour shows correct step
    document.location.hash = ''

  it '`backdrop` parameter should show backdrop with step', ->
    @tour = new Tour
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      backdrop: false
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      backdrop: true
    @tour.start()
    expect($('.tour-backdrop').length).toBe 0 # disable backdrop
    expect($('.tour-step-backdrop').length).toBe 0 # disable backdrop
    @tour.next()
    expect($('.tour-backdrop').length).toBe 4 # enable backdrop
    expect($('.tour-step-backdrop').length).toBe 1 # enable backdrop
    @tour.end()
    expect($('.tour-backdrop').length).toBe 0 # disable backdrop
    expect($('.tour-step-backdrop').length).toBe 0 # disable backdrop

  it 'step with backdrop and invalid selector should not attempt to create an overlay element', ->
    @tour = new Tour
    @tour._showOverlayElement backdropElement: '#nonExistingElement'
    expect($('.tour-backdrop').length).toBe 0

  it 'should render the padding on the backdrop element', ->
    @tour = new Tour
      backdrop: true
    $firstElement = $('<div></div>', width: 10, height: 10).appendTo('body')
    $secondElement = $('<div></div>').css(
      position: 'absolute'
      top: 100
      left: 300
      width: 10
      height: 10
    ).appendTo('body')

    firstPadding = 20
    secondPadding =
      top: 40
      right: 30
      bottom: 20
      left: 10

    @tour.addStep
      backdrop: true
      backdropPadding: firstPadding
      element: $firstElement
    @tour.addStep
      backdrop: true
      backdropPadding: secondPadding
      element: $secondElement
    @tour.start()
    expect(@tour.backdrops.top.offset().top + @tour.backdrops.top.height())
    .toBe 0

    expect(@tour.backdrops.left.offset().top)
    .toBe $firstElement.offset().top - firstPadding
    expect(@tour.backdrops.left.offset().top + @tour.backdrops.left.height())
    .toBe $firstElement.offset().top + $firstElement.height() + firstPadding
    expect(@tour.backdrops.left.offset().left + @tour.backdrops.left.width())
    .toBe 0

    expect(@tour.backdrops.bottom.offset().top)
    .toBe $firstElement.offset().top + $firstElement.height() + firstPadding

    expect(@tour.backdrops.right.offset().top)
    .toBe $firstElement.offset().top - firstPadding
    expect(@tour.backdrops.right.offset().top + @tour.backdrops.right.height())
    .toBe $firstElement.offset().top + $firstElement.height() + firstPadding
    expect(@tour.backdrops.right.offset().left)
    .toBe $firstElement.offset().left + $firstElement.width() + firstPadding

    @tour.next()
    expect(@tour.backdrops.top.offset().top + @tour.backdrops.top.height())
    .toBe $secondElement.offset().top - secondPadding.top

    expect(@tour.backdrops.left.offset().top)
    .toBe $secondElement.offset().top - secondPadding.top
    expect(@tour.backdrops.left.offset().top + @tour.backdrops.left.height())
    .toBe $secondElement.offset().top + $secondElement.height() + secondPadding.bottom
    expect(@tour.backdrops.left.offset().left + @tour.backdrops.left.width())
    .toBe $secondElement.offset().left - secondPadding.left

    expect(@tour.backdrops.bottom.offset().top)
    .toBe $secondElement.offset().top + $secondElement.height() + secondPadding.bottom

    expect(@tour.backdrops.right.offset().top)
    .toBe $secondElement.offset().top - secondPadding.top
    expect(@tour.backdrops.right.offset().top + @tour.backdrops.right.height())
    .toBe $secondElement.offset().top + $secondElement.height() + secondPadding.bottom
    expect(@tour.backdrops.right.offset().left)
    .toBe $secondElement.offset().left + $secondElement.width() + secondPadding.right

  it '`basePath` should prepend the path to the steps', ->
    @tour = new Tour
      basePath: 'test/'
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      path: 'test.html'

    # Tour adds basePath to step path
    expect(
      @tour._isRedirect(
        @tour.getStep(0).host,
        @tour._options.basePath + @tour.getStep(0).path,
        href: '', pathname: 'test/test.html', search: '', hash: ''
      )
    ).toBe false

  it 'should evaluate the host correctly', ->
    @tour = new Tour

    expect(
      @tour._isRedirect(
        'http://sub.exemple.com',
        '/test.html',
        {
          origin: 'http://exemple.com'
          href: 'http://exemple.com/test.html'
          pathname: '/test.html'
          search: ''
          hash: ''
        }
      )
    ).toBe true

    expect(
      @tour._isRedirect(
        'http://sub.exemple.com',
        '/test.html',
        {
          origin: 'http://sub.exemple.com'
          href: 'http://sub.exemple.com/test.html'
          pathname: '/test.html'
          search: ''
          hash: ''
        }
      )
    ).toBe false

    expect(
      @tour._isRedirect(
        /http:\/\/.*\.exemple\.com/,
        '/test.html',
        {
          origin: 'http://sub.exemple.com'
          href: 'http://sub.exemple.com/test.html'
          pathname: '/test.html'
          search: ''
          hash: ''
        }
      )
    ).toBe false

    expect(
      @tour._isRedirect(
        /http:\/\/exemple\.com/,
        '/test.html',
        {
          origin: 'http://sub.exemple.com'
          href: 'http://sub.exemple.com/test.html'
          pathname: '/test.html'
          search: ''
          hash: ''
        }
      )
    ).toBe true

  it 'with `onNext` option should run the callback before showing the next step', ->
    tour_test = 0
    @tour = new Tour
      onNext: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect(tour_test).toBe 2

  it '`showStep` should not show step if tour ended', ->
    @tour = new Tour
      onNext: (t) -> t.end()
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect($('.popover').length).toBe 0

  it '`addStep` with onNext option should run the callback before showing the next step', ->
    tour_test = 0
    @tour = new Tour
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      onNext: -> tour_test = 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect(tour_test).toBe 0 # tour does not run onNext when next step is not called
    @tour.next()
    expect(tour_test).toBe 2 # tour runs onNext when next step is called

  it 'with `onPrev` option should run the callback before showing the prev step', ->
    tour_test = 0
    @tour = new Tour
      onPrev: -> tour_test += 2
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    @tour.prev()
    expect(tour_test).toBe 2 # tour runs onPrev when prev step is called

  it '`addStep` with `onPrev` option should run the callback before showing the prev step', ->
    tour_test = 0
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      onPrev: -> tour_test = 2
    @tour.start()
    expect(tour_test).toBe 0 # tour does not run onPrev when prev step is not called
    @tour.next()
    @tour.prev()
    expect(tour_test).toBe 2 # tour runs onPrev when prev step is called

  it 'with `onRedirectError` option should run the callback when redirection failed', ->
    tour_test = 0
    @tour = new Tour
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      path: '/path'
      onRedirectError: -> tour_test = 2

    @tour._setState 'redirect_to', 0 # tour has previously redirected to step '0'
    @tour.start()
    expect(tour_test).toBe 2 # tour runs onRedirectError when redirection failed

  it 'should render custom navigation template', ->
    @tour = new Tour
      template:
        '<div class="popover tour">
          <div class="arrow"></div>
          <h3 class="popover-title"></h3>
          <div class="popover-content"></div>
          <div class="popover-navigation">
            <a data-role="prev"></a>
            <a data-role="next"></a>
            <a data-role="end"></a>
          </div>
        </div>'
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.next()
    expect($('.popover .popover-navigation a').length).toBe 3

  it 'should have `data-role` attribute for navigation template', ->
    @tour = new Tour
    template = $(@tour._options.template)
    expect(template.find('*[data-role=next]').size()).toBe 1
    expect(template.find('*[data-role=prev]').size()).toBe 1
    expect(template.find('*[data-role=end]').size()).toBe 1

  it 'should unbind click events when hiding step (in reflex mode)', ->
    $element = $('<div></div>').appendTo('body')
    @tour = new Tour
    @tour.addStep
      element: $element
      reflex: true
    @tour.addStep(element: $('<div></div>').appendTo('body'))

    expect($._data($element[0], 'events')).not.toBeDefined()
    @tour.start()
    expect($._data($element[0], 'events').click.length).toBeGreaterThan 0
    expect($._data($element[0], 'events').click[0].namespace).toBe "tour-#{@tour._options.name}"

    $.each [0..10], =>
      @tour.next()
      expect($._data($element[0], 'events')).not.toBeDefined()
      @tour.prev()
      expect($._data($element[0], 'events').click.length).toBeGreaterThan 0
      expect($._data($element[0], 'events').click[0].namespace).toBe "tour-#{@tour._options.name}"

  it 'should add `tour-{tourName}` and `tour-{tourName}-{stepId}` classses to the popover', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.showStep(0)
    expect($('.popover').hasClass("tour-#{@tour._options.name}")).toBe true
    expect($('.popover').hasClass("tour-#{@tour._options.name}-0")).toBe true

  it 'should add `tour-{tourName}-element` and `tour-{tourName}-{stepId}-element` classses to the popover element', ->
    @tour = new Tour
    $element = $ '<div></div>'
    @tour.addStep element: $element.appendTo 'body'
    @tour.showStep 0
    expect($element.hasClass "tour-#{@tour._options.name}-element").toBe true
    expect($element.hasClass "tour-#{@tour._options.name}-0-element").toBe true

  # orphan
  it 'should show orphan steps', ->
    @tour = new Tour
    @tour.addStep
      orphan: true
    @tour.showStep(0)
    expect($('.popover').length).toBe 1
    $('.popover').remove()

  it 'should add `orphan` class to the popover', ->
    @tour = new Tour
    @tour.addStep
      orphan: true
    @tour.showStep(0)
    expect($('.popover').hasClass('orphan')).toBe true
    $('.popover').remove()

  it 'should use orphan template to show orphan steps', ->
    @tour = new Tour
    step = orphan: '<div class="popover orphan-custom-template"></div>'
    @tour.addStep step
    template = @tour._template(step, 0)

    expect($(template).hasClass('orphan-custom-template')).toBe true

  it 'should not use orphan template to show steps', ->
    @tour = new Tour
    step =
      orphan: '<div class="popover orphan-custom-template"></div>'
      element: $('<div></div>').appendTo('body')
    @tour.addStep step
    template = @tour._template(step, 0)

    expect($(template).hasClass('orphan-custom-template')).toBe false

  it 'should execute orphan template if it is a function', ->
    @tour = new Tour
    step = orphan: -> '<div class="popover orphan-custom-template"></div>'
    @tour.addStep step
    template = @tour._template(step, 0)

    expect($(template).hasClass('orphan-custom-template')).toBe true

  it 'handles quota_exceeded exceptions', ->
    @tour = new Tour
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    spyOn(@tour._options.storage, 'setItem').and.callFake ->
      throw new Error 'QUOTA_EXCEEDED_ERR', 'QUOTA_EXCEEDED_ERR: DOM Exception 22'
    spyOn(@tour, '_setState')
    @tour._setState('test', '1')
    expect(=> @tour._setState).not.toThrow()

  it 'should not try to scroll to non-existing element', ->
    @tour = new Tour
      orphan: true
    @tour.addStep
      element: '#nonExistingElement'
    @tour.showStep 0
    expect($('.popover').length).toBe 1

  # duration
  it 'should start the timer', ->
    @tour = new Tour
      duration: 5000
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect(@tour._timer).toBeDefined()
    expect(@tour._duration).toBeDefined()
    window.clearTimeout(@tour._timer)

  it 'should pause the timer on pause', ->
    @tour = new Tour
      duration: 5000
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    window.setTimeout( =>
      @tour.pause()
      expect(@tour._timer).toBe null
      expect(@tour._duration).toBeGreaterThan(0).toBeLessThan(5000)
    , 1000)

  it 'should stop the timer on hideStep', ->
    @tour = new Tour
      duration: 5000
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.hideStep(0)
    expect(@tour._timer).toBe null
    expect(@tour._duration).toBe null

  it 'should stop the timer on end', ->
    @tour = new Tour
      duration: 5000
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    @tour.end()
    expect(@tour._timer).toBe null
    expect(@tour._duration).toBe null

  it 'should call window.setTimeout when delay is defined', ->
    counter = 0
    initialTimeout = window.setTimeout
    window.setTimeout = (callback, duration) ->
      counter++
      callback()

    @tour = new Tour
      delay: {
        show: 300
        hide: 400
      }
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.addStep(element: $('<div></div>').appendTo('body'))
    @tour.start()
    expect(counter).toBe 2
    @tour.next()
    expect(counter).toBe 4
    @tour.end()
    expect(counter).toBe 5

    window.setTimeout = initialTimeout

  ### TODO: fix $.support.transition conflict between jquery and bootstrap
  it 'should not display inactive popover upon rapid navigation', ->
    # Flag that gives signal to the async test that it should evaluate.
    $.support.transition = true
    $.fx.off = false
    isStepShown = false

    # Cleanup all leftover popovers from previous tests.
    $('.popover').remove()

    # Setup two-step tour. The problem should occur when switching from first
    # step to the second while the transition effect of the first one is still
    # active.
    @tour = new Tour
    @tour.addStep element: $('<div></div>').appendTo('body')
    @tour.addStep
      element: $('<div></div>').appendTo('body')
      onShown: ->
        isStepShown = true

    # Request the first step and immediately the second one. This way the first
    # step won't be displayed when the second step is requested, so the request
    # for second step can not cleanup existing popovers yet.
    runs ->
      @tour.goTo(0)
      @tour.goTo(1)
    waitsFor ->
      isStepShown
    , 'The second step should be displayed.', 1000
    runs -> expect($('.popover').length).toBe 1
  ###

/* ========================================================================
 * bootstrap-tour - v0.11.0
 * http://bootstraptour.com
 * ========================================================================
 * Copyright 2012-2015 Ulrich Sossou
 *
 * ========================================================================
 * Licensed under the MIT License (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://opensource.org/licenses/MIT
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * ========================================================================
 *
 * Updated for CS by FFS 2018 - v0.5
 * Features added:
 *
 
 1. onNext/onPrevious - prevent auto-move to next step, allow .goTo
 2. *** Do not call Tour.init *** - fixed tours with hidden elements on page reload
 3. Dynamically determine step element by function
 4. Only continue tour when reflex element is clicked using reflexOnly
 5. Call onElementUnavailable if step element is missing
 6. Scroll flicker/continual step reload fixed
 7. Magic progress bar and progress text, plus options to customize per step
 8. Prevent user interaction with element using preventInteraction
 9. Wait for arbitrary DOM element to be visible before showing tour step/crapping out due to missing element, using delayOnElement
 10. Handle bootstrap modal dialogs better - autodetect modals or children of modals, and call onModalHidden when user dismisses modal without following tour steps
 11. Automagically fixes drawing issues with Bootstrap Selectpicker (https://github.com/snapappointments/bootstrap-select/)
 
 --------------
	1. Control flow from onNext() / onPrevious() options:
 			Returning false from onNext/onPrevious handler will prevent Tour from automatically moving to the next/previous step.
			Tour flow methods (Tour.goTo etc) now also work correctly in onNext/onPrevious.
			Option is available per step or globally:
			
			var tourSteps = [
								{
									element: "#inputBanana",
									title: "Bananas!",
									content: "Bananas are yellow, except when they're not",
									onNext: function(tour){
										if($('#inputBanana').val() !== "banana")
										{
											// no banana? highlight the banana field
											$('#inputBanana').css("background-color", "red");
											// do not jump to the next tour step!
											return false;
										}
									}
								}
							];
			
			var Tour=new Tour({
								steps: tourSteps,
								onNext: function(tour)
										{
											if(someVar = true)
											{
												// force the tour to jump to slide 3
												tour.goTo(3);
												// Prevent default move to next step - important!
												return false;
											}
										}
							});
 
 --------------
	2. Do not call Tour.init
			When setting up Tour, do not call Tour.init(). 
			Call Tour.start() to start/resume the Tour from previous step
			Call Tour.restart() to always start Tour from first step
			
			Tour.init() was a redundant method that caused conflict with hidden Tour elements.
			
---------------
	3. Dynamically determine element by function
			Step "element:" option allows element to be determined programmatically. Return a jquery object.
			The following is possible:
			
			var tourSteps = [
								{
									element: function() { return $(document).find("...something..."); },
									title: "Dynamic",
									content: "Element found by function"
								},
								{
									element: "#static",
									title: "Static",
									content: "Element found by static ID"
								}								
							];		
							
---------------
	4. Only continue tour when reflex element is clicked
			Use step option reflexOnly in conjunction with step option reflex to automagically hide the "next" button in the tour, and only continue when the user clicks the element:
			var tourSteps = [
								{
									element: "#myButton",
									reflex: true,
									reflexOnly: true,
									title: "Click it",
									content: "Click to continue, or you're stuck"
								}								
							];				
							
----------------
	5. Call function when element is missing
			If the element specified in the step (static or dynamically determined as per feature #3), onElementUnavailable is called.
			Function signature: function(tour, stepNumber) {}
			Option is available at global and per step levels.
			
			function tourBroken(tour, stepNumber)
			{ 
				alert("Uhoh, tour element is done broke on step number " + stepNumber);
			}
			
			var tourSteps = [
								{
									element: "#btnMagic",
									onElementUnavailable: tourBroken,
									title: "Hold my beer",
									content: "now watch this"
								}					
							];

---------------
	6. Scroll flicker / continue reload fixed
			Original Tour constantly reloaded the current tour step on scroll & similar events. This produced flickering, constant reloads and therefore constant calls to all the step function calls.
			This is now fixed. Scrolling the browser window does not cause the tour step to reload.
			
			IMPORTANT: orphan steps are stuck to the center of the screen. However steps linked to elements ALWAYS stay stuck to their element, even if user scrolls the element & tour popover
						off the screen. This is my personal preference, as original functionality of tour step moving with the scroll even when the element was off the viewport seemed strange.
						
---------------
	7. Progress bar & progress text:
			Use the following options globally or per step to show tour progress:
			showProgressBar - shows a bootstrap progress bar for tour progress at the top of the tour content
			showProgressText - shows a textual progress (N/X, i.e.: 1/24 for slide 1 of 24) in the tour title
			
			var tourSteps = [
								{
									element: "#inputBanana",
									title: "Bananas!",
									content: "Bananas are yellow, except when they're not",
								},
								{
									element: "#inputOranges",
									title: "Oranges!",
									content: "Oranges are not bananas",
									showProgressBar: false,	// don't show the progress bar on this step only
									showProgressText: false, // don't show the progress text on this step only
								}
							];
			var Tour=new Tour({
								steps: tourSteps,
								showProgressBar: true, // default show progress bar
								showProgressText: true, // default show progress text
							});
							
	7b. Customize the progressbar/progress text:
			In conjunction with 7a, provide the following functions globally or per step to draw your own progressbar/progress text:
			
			getProgressBarHTML(percent)
			getProgressTextHTML(stepNumber, percent, stepCount)
			
			These will be called when each step is shown, with the appropriate percentage/step number etc passed to your function. Return an HTML string of a "drawn" progress bar/progress text
			which will be directly inserted into the tour step.
			
			Example:
			var tourSteps = [
								{
									element: "#inputBanana",
									title: "Bananas!",
									content: "Bananas are yellow, except when they're not",
								},
								{
									element: "#inputOranges",
									title: "Oranges!",
									content: "Oranges are not bananas",
									getProgressBarHTML:	function(percent)
														{
															// override the global progress bar function for this step
															return '<div>You're ' + percent + ' of the way through!</div>';
														}
								}
							];
			var Tour=new Tour({
								steps: tourSteps,
								showProgressBar: true, // default show progress bar
								showProgressText: true, // default show progress text
								getProgressBarHTML: 	function(percent)
														{
															// default progress bar for all steps. Return valid HTML to draw the progress bar you want
															return '<div class="progress"><div class="progress-bar progress-bar-striped" role="progressbar" style="width: ' + percent + '%;"></div></div>';
														},
								getProgressTextHTML: 	function(stepNumber, percent, stepCount)
														{
															// default progress text for all steps
															return 'Slide ' + stepNumber + "/" + stepCount;
														},
													
							});

----------------
	8. Prevent interaction with element
			Sometimes you want to highlight a DOM element (button, input field) for a tour step, but don't want the user to be able to interact with it.
			Use preventInteraction to stop the user touching the element:
			
			var tourSteps = [
								{
									element: "#btnMCHammer",
									preventInteraction: true,
									title: "Hammer Time",
									content: "You can't touch this"
								}								
							];						

----------------
	9. Wait for an element to appear before continuing tour
			Sometimes a tour step element might not be immediately ready because of transition effects etc. This is a specific issue with bootstrap select, which is relatively slow to show the selectpicker
			dropdown after clicking.
			Use delayOnElement to instruct Tour to wait for **ANY** element to appear before showing the step (or crapping out due to missing element). Yes this means the tour step element can be one DOM
			element, but the delay will wait for a completely separate DOM element to appear. This is really useful for hidden divs etc.
			Use in conjunction with onElementUnavailable for robust tour step handling.
			
			delayOnElement is an object with the following:
							delayOnElement: {
												delayElement: "#waitForMe", // the element to wait to become visible, or the string literal "element" to use the step element
												maxDelay: 2000, // optional milliseconds to wait/timeout for the element, before crapping out. If maxDelay is not specified, this is 2000ms by default
											}

			var tourSteps = [
								{
									element: "#btnPrettyTransition",
									delayOnElement:	{
														delayElement: "element" // use string literal "element" to wait for this step's element, i.e.: #btnPrettyTransition
													},
									title: "Ages",
									content: "This button takes ages to appear"
								},						
								{
									element: "#inputUnrelated",
									delayOnElement:	{
														delayElement: "#divStuff" // wait until DOM element "divStuff" is visible before showing this tour step against DOM element "inputUnrelated"
													},
									title: "Waiting",
									content: "This input is nice, but you only see this step when the other div appears"
								},
								{								
									element: "#btnDontForgetThis",
									delayOnElement:	{
														delayElement: "element", // use string literal "element" to wait for this step's element, i.e.: #btnDontForgetThis
														maxDelay: 5000	// wait 5 seconds for it to appear before timing out
													},
									title: "Cool",
									content: "Remember the onElementUnavailable option!",
									onElementUnavailable: 	function(tour, stepNumber)
															{
																// This will be called if btnDontForgetThis is not visible after 5 seconds
																console.log("Well that went badly wrong");
															}
								},						
							];

----------------
	10. Trigger when modal closes
			If tour element is a modal, or is a DOM element inside a modal, the element can disappear "at random" if the user dismisses the dialog.
			In this case, onModalHidden global and per step function is called. Only functional when step is not an orphan.
			This is useful if a tour includes a step that launches a modal, and the tour requires the user to take some actions inside the modal before OK'ing it and moving to the next
			tour step.
			
			Return (int) step number to immediately move to that step
			Return exactly false to not change tour state in any way - this is useful if you need to reshow the modal because some validation failed
			Return anything else to move to the next step
			
			element === Bootstrap modal, or element parent === bootstrap modal is automatically detected.
			
			var Tour=new Tour({
								steps: tourSteps,
								onModalHidden: 	function(tour, stepNumber)
												{
													console.log("Well damn, this step's element was a modal, or inside a modal, and the modal just done got dismissed y'all. Moving to step 3.");
													
													// move to step number 3
													return 3;
												},
							});			

							
			var Tour=new Tour({
								steps: tourSteps,
								onModalHidden: 	function(tour, stepNumber)
												{
													if(validateSomeModalContent() == false)
													{
														// The validation failed, user dismissed modal without properly taking actions. 
														// Show the modal again
														showModalAgain();
														
														// Instruct tour to stay on same step
														return false;
													}
													else
													{
														// Content was valid. Return null or do nothing to instruct tour to continue to next step
													}
												},
							});			

----------------
	11.	Fix conflict with Bootstrap Selectpicker: https://github.com/snapappointments/bootstrap-select/
		Selectpicker draws a custom select. Tour now automagically finds and adjusts the selectpicker dropdown so that it appears correctly within the tour
		
 * 
 */

var bind = function (fn, me) {
	return function () {
		return fn.apply(me, arguments);
	};
};

(function (window, factory) {
	if (typeof define === 'function' && define.amd) {
		return define(['jquery'], function (jQuery) {
			return window.Tour = factory(jQuery);
		});
	} else if (typeof exports === 'object') {
		return module.exports = factory(require('jquery'));
	} else {
		return window.Tour = factory(window.jQuery);
	}
})(window, function ($) {
	var Tour,
	document;
	document = window.document;
	Tour = (function () {
		function Tour(options) {
			this._showPopoverAndOverlay = bind(this._showPopoverAndOverlay, this);
			var storage;
			try {
				storage = window.localStorage;
			} catch (error) {
				storage = false;
			}
			this._options = $.extend({
					name: 'tour',
					steps: [],
					container: 'body',
					autoscroll: true,
					keyboard: true,
					storage: storage,
					debug: false,
					backdrop: false,
					backdropContainer: 'body',
					backdropPadding: 0,
					redirect: true,
					orphan: false,
					duration: false,
					delay: false,
					basePath: '',
					template: '<div class="popover" role="tooltip"> <div class="arrow"></div> <h3 class="popover-title"></h3> <div class="popover-content"></div> <div class="popover-navigation"> <div class="btn-group"> <button class="btn btn-sm btn-default" data-role="prev">&laquo; Prev</button> <button class="btn btn-sm btn-default" data-role="next">Next &raquo;</button> <button class="btn btn-sm btn-default" data-role="pause-resume" data-pause-text="Pause" data-resume-text="Resume">Pause</button> </div> <button class="btn btn-sm btn-default" data-role="end">End tour</button> </div> </div>',
					showProgressBar: true,
					showProgressText: true,
					getProgressBarHTML: null,//function(percent) {},
					getProgressTextHTML: null,//function(stepNumber, percent, stepCount) {},
					afterSetState: function (key, value) {},
					afterGetState: function (key, value) {},
					afterRemoveState: function (key) {},
					onStart: function (tour) {},
					onEnd: function (tour) {},
					onShow: function (tour) {},
					onShown: function (tour) {},
					onHide: function (tour) {},
					onHidden: function (tour) {},
					onNext: function (tour) {},
					onPrev: function (tour) {},
					onPause: function (tour, duration) {},
					onResume: function (tour, duration) {},
					onRedirectError: function (tour) {},
					onElementUnavailable: null, // function (tour, stepNumber) {},
					onModalHidden: null, // function(tour, stepNumber) {}
				}, options);
			this._force = false;
			this._inited = false;
			this._current = null;
			this.backdrops = [];
			this;
		}

		Tour.prototype.addSteps = function (steps) {
			var j,
			len,
			step;
			for (j = 0, len = steps.length; j < len; j++) {
				step = steps[j];
				this.addStep(step);
			}
			return this;
		};

		Tour.prototype.addStep = function (step) {
			this._options.steps.push(step);
			return this;
		};
		
		Tour.prototype.getStepCount = function() {
			return this._options.steps.length;
		};

		Tour.prototype.getStep = function (i) {
			if (this._options.steps[i] != null) {
				
				if(typeof(this._options.steps[i].element) == "function")
				{
					this._options.steps[i].element = this._options.steps[i].element();
				}
				
				return $.extend({
					id: "step-" + i,
					path: '',
					host: '',
					placement: 'right',
					title: '',
					content: '<p></p>',
					next: i === this._options.steps.length - 1 ? -1 : i + 1,
					prev: i - 1,
					animation: true,
					container: this._options.container,
					autoscroll: this._options.autoscroll,
					backdrop: this._options.backdrop,
					backdropContainer: this._options.backdropContainer,
					backdropPadding: this._options.backdropPadding,
					redirect: this._options.redirect,
					reflexElement: this._options.steps[i].element,
					preventInteraction: false,
					backdropElement: this._options.steps[i].element,
					orphan: this._options.orphan,
					duration: this._options.duration,
					delay: this._options.delay,
					template: this._options.template,
					showProgressBar: this._options.showProgressBar,
					showProgressText: this._options.showProgressText,
					getProgressBarHTML: this._options.getProgressBarHTML,
					getProgressTextHTML: this._options.getProgressTextHTML,
					onShow: this._options.onShow,
					onShown: this._options.onShown,
					onHide: this._options.onHide,
					onHidden: this._options.onHidden,
					onNext: this._options.onNext,
					onPrev: this._options.onPrev,
					onPause: this._options.onPause,
					onResume: this._options.onResume,
					onRedirectError: this._options.onRedirectError,
					onElementUnavailable: this._options.onElementUnavailable,
					onModalHidden: this._options.onModalHidden
				}, this._options.steps[i]);
			}
		};

		Tour.prototype.init = function (force) {
			this._force = force;
			if (this.ended()) {
				this._debug('Tour ended, init prevented.');
				return this;
			}
			this.setCurrentStep();
			this._initMouseNavigation();
			this._initKeyboardNavigation();
			this._onResize((function (_this) {
					return function () {
						return _this.showStep(_this._current);
					};
				})(this));
			this._onScroll((function (_this) {
					return function () {
						return _this._showPopoverAndOverlay(_this._current);
					};
				})(this));
/*
			// Removed - .init is an unnecessary call, .start force calls .init if tour is not initialized. This code creates conflict
			// where page has hidden elements, page is reloaded, tour is then forced to start on step N when hidden element is not shown yet
  			if (this._current !== null) {
				this.showStep(this._current);
			}
 */			this._inited = true;
			return this;
		};

		Tour.prototype.start = function (force) {
			var promise;
			if (force == null) {
				force = false;
			}
			if (!this._inited) {
				this.init(force);
			}

			// removed if condition - tour should always start when .start is called. Original flow prevented tour from start if _current step index was set (tour already started)
			//if (this._current === null) {
				promise = this._makePromise(this._options.onStart != null ? this._options.onStart(this) : void 0);
				this._callOnPromiseDone(promise, this.showStep, this._current);
			// }

			return this;
		};

		Tour.prototype.next = function () {
			var promise;
			promise = this.hideStep(this._current, this._current + 1);
			return this._callOnPromiseDone(promise, this._showNextStep);
		};

		Tour.prototype.prev = function () {
			var promise;
			promise = this.hideStep(this._current, this._current - 1);
			return this._callOnPromiseDone(promise, this._showPrevStep);
		};

		Tour.prototype.goTo = function (i) {
			var promise;
			promise = this.hideStep(this._current, i);
			return this._callOnPromiseDone(promise, this.showStep, i);
		};

		Tour.prototype.end = function () {
			var endHelper,
			promise;
			endHelper = (function (_this) {
				return function (e) {
					$(document).off("click.tour-" + _this._options.name);
					$(document).off("keyup.tour-" + _this._options.name);
					$(window).off("resize.tour-" + _this._options.name);
					$(window).off("scroll.tour-" + _this._options.name);
					_this._setState('end', 'yes');
					_this._inited = false;
					_this._force = false;
					_this._clearTimer();
					if (_this._options.onEnd != null) {
						return _this._options.onEnd(_this);
					}
				};
			})(this);
			promise = this.hideStep(this._current);
			return this._callOnPromiseDone(promise, endHelper);
		};

		Tour.prototype.ended = function () {
			return !this._force && !!this._getState('end');
		};

		Tour.prototype.restart = function () {
			this._removeState('current_step');
			this._removeState('end');
			this._removeState('redirect_to');
			return this.start();
		};

		Tour.prototype.pause = function () {
			var step;
			step = this.getStep(this._current);
			if (!(step && step.duration)) {
				return this;
			}
			this._paused = true;
			this._duration -= new Date().getTime() - this._start;
			window.clearTimeout(this._timer);
			this._debug("Paused/Stopped step " + (this._current + 1) + " timer (" + this._duration + " remaining).");
			if (step.onPause != null) {
				return step.onPause(this, this._duration);
			}
		};

		Tour.prototype.resume = function () {
			var step;
			step = this.getStep(this._current);
			if (!(step && step.duration)) {
				return this;
			}
			this._paused = false;
			this._start = new Date().getTime();
			this._duration = this._duration || step.duration;
			this._timer = window.setTimeout((function (_this) {
						return function () {
							if (_this._isLast()) {
								return _this.next();
							} else {
								return _this.end();
							}
						};
					})(this), this._duration);
			this._debug("Started step " + (this._current + 1) + " timer with duration " + this._duration);
			if ((step.onResume != null) && this._duration !== step.duration) {
				return step.onResume(this, this._duration);
			}
		};
		
		Tour.prototype.reshowCurrentStep = function()
		{
			var promise;
			promise = this.hideStep(this._current, this._current);
			return this._callOnPromiseDone(promise, this.showStep, this._current);
		}

		Tour.prototype.hideStep = function (i, iNext) {
			var hideDelay,
			hideStepHelper,
			promise,
			step;
			step = this.getStep(i);
			if (!step) {
				return;
			}
			this._clearTimer();
			promise = this._makePromise(step.onHide != null ? step.onHide(this, i) : void 0);
			
			hideStepHelper = (function (_this)
			{
				return function (e)
				{
					var $element,
					next_step;
					$element = $(step.element);
					if (!($element.data('bs.popover') || $element.data('popover')))
					{
						$element = $('body');
					}
					
					$element.popover('destroy').removeClass("tour-" + _this._options.name + "-element tour-" + _this._options.name + "-" + i + "-element").removeData('bs.popover');
					
					if (step.reflex)
					{
						$(step.reflexElement).removeClass('tour-step-element-reflex').off((_this._reflexEvent(step.reflex)) + ".tour-" + _this._options.name);
					}
					
					if (step.backdrop)
					{
						next_step = (iNext != null) && _this.getStep(iNext);
						if (!next_step || !next_step.backdrop || next_step.backdropElement !== step.backdropElement) {
							_this._hideOverlayElement(step);
						}
					}
					
					if (step.onHidden != null)
					{
						return step.onHidden(_this);
					}
				};
			})(this);
			
			hideDelay = step.delay.hide || step.delay;
			if ({}
				.toString.call(hideDelay) === '[object Number]' && hideDelay > 0) {
				this._debug("Wait " + hideDelay + " milliseconds to hide the step " + (this._current + 1));
				window.setTimeout((function (_this) {
						return function () {
							return _this._callOnPromiseDone(promise, hideStepHelper);
						};
					})(this), hideDelay);
			} else {
				this._callOnPromiseDone(promise, hideStepHelper);
			}
			return promise;
		};

		Tour.prototype.showStep = function (i) {
			var path,
			promise,
			showDelay,
			showStepHelper,
			skipToPrevious,
			step;
			if (this.ended()) {
				this._debug('Tour ended, showStep prevented.');
				return this;
			}
			step = this.getStep(i);
			if (!step) {
				return;
			}
			
			skipToPrevious = i < this._current;
			promise = this._makePromise(step.onShow != null ? step.onShow(this, i) : void 0);
			this.setCurrentStep(i);
			
			path = (function () {
				switch ({}
					.toString.call(step.path)) {
				case '[object Function]':
					return step.path();
				case '[object String]':
					return this._options.basePath + step.path;
				default:
					return step.path;
				}
			}).call(this);
			
			
			if (step.redirect && this._isRedirect(step.host, path, document.location)) {
				this._redirect(step, i, path);
				if (!this._isJustPathHashDifferent(step.host, path, document.location)) {
					return;
				}
			}
			
			
			showStepHelper = (function (_this) {
				return function (e) {
					if (_this._isOrphan(step)) {
						if (step.orphan === false)
						{
							_this._debug("Skip the orphan step " + (_this._current + 1) + ".\nOrphan option is false and the element does not exist or is hidden.");
							
							if(typeof(step.onElementUnavailable) == "function")
							{
								step.onElementUnavailable(_this, _this._current + 1);	
							}
							
							if (skipToPrevious) {
								_this._showPrevStep();
							} else {
								_this._showNextStep();
							}
							return;
						}
						_this._debug("Show the orphan step " + (_this._current + 1) + ". Orphans option is true.");
					}
					if (step.autoscroll) {
						_this._scrollIntoView(i);
					} else {
						_this._showPopoverAndOverlay(i);
					}
					
					if (step.duration) {
						return _this.resume();
					}
				};
			})(this);
			
			// delay in millisec specified in step options
			showDelay = step.delay.show || step.delay;
			if ({}
				.toString.call(showDelay) === '[object Number]' && showDelay > 0) {
				this._debug("Wait " + showDelay + " milliseconds to show the step " + (this._current + 1));
				window.setTimeout((function (_this) {
						return function () {
							return _this._callOnPromiseDone(promise, showStepHelper);
						};
					})(this), showDelay);
			}
			else
			{
				if(step.delayOnElement)
				{
					// delay by element existence or max delay (default 2 sec)
					var $delayElement = null;
					var delayFunc = null;
					var _this = this;

					if(typeof(step.delayOnElement.delayElement) == "function")
						$delayElement = step.delayOnElement.delayElement();
					else if(step.delayOnElement.delayElement == "element")
						$delayElement = $(step.element);
					else
						$delayElement = $(step.delayOnElement.delayElement);
					
					delayMax = (step.delayOnElement.maxDelay ? step.delayOnElement.maxDelay : 2000);
					this._debug("Wait for element " + $delayElement[0].tagName + " visible or max " + delayMax + " milliseconds to show the step " + (this._current + 1));
					
					delayFunc = window.setInterval(	function()
													{
														_this._debug("Wait for element " + $delayElement[0].tagName + ": checking...");
														if($delayElement.is(':visible'))
														{
															_this._debug("Wait for element " + $delayElement[0].tagName + ": found, showing step");
															window.clearInterval(delayFunc);														
															delayFunc = null;
															return _this._callOnPromiseDone(promise, showStepHelper);
														}
													}, 250);
					
					//	set max delay to greater than default interval check for element appearance
					if(delayMax < 250)
						delayMax = 251;
					
					window.setTimeout(	function ()
										{ 
											if(delayFunc)
											{
												_this._debug("Wait for element " + $delayElement[0].tagName + ": max timeout reached without element found");
												window.clearInterval(delayFunc);
												
												// showStepHelper will handle broken/missing/invisible element
												return _this._callOnPromiseDone(promise, showStepHelper);
											}
										}, delayMax);
				}
				else
				{
					// no delay by milliseconds or delay by time
					this._callOnPromiseDone(promise, showStepHelper);
				}
			}
			
			return promise;
		};

		Tour.prototype.getCurrentStep = function () {
			return this._current;
		};

		Tour.prototype.setCurrentStep = function (value) {
			if (value != null) {
				this._current = value;
				this._setState('current_step', value);
			} else {
				this._current = this._getState('current_step');
				this._current = this._current === null ? 0 : parseInt(this._current, 10);
			}
			return this;
		};

		Tour.prototype.redraw = function () {
			return this._showOverlayElement(this.getStep(this.getCurrentStep()));
		};

		Tour.prototype._setState = function (key, value) {
			var e,
			keyName;
			if (this._options.storage) {
				keyName = this._options.name + "_" + key;
				try {
					this._options.storage.setItem(keyName, value);
				} catch (error) {
					e = error;
					if (e.code === DOMException.QUOTA_EXCEEDED_ERR) {
						this._debug('LocalStorage quota exceeded. State storage failed.');
					}
				}
				return this._options.afterSetState(keyName, value);
			} else {
				if (this._state == null) {
					this._state = {};
				}
				return this._state[key] = value;
			}
		};

		Tour.prototype._removeState = function (key) {
			var keyName;
			if (this._options.storage) {
				keyName = this._options.name + "_" + key;
				this._options.storage.removeItem(keyName);
				return this._options.afterRemoveState(keyName);
			} else {
				if (this._state != null) {
					return delete this._state[key];
				}
			}
		};

		Tour.prototype._getState = function (key) {
			var keyName,
			value;
			if (this._options.storage) {
				keyName = this._options.name + "_" + key;
				value = this._options.storage.getItem(keyName);
			} else {
				if (this._state != null) {
					value = this._state[key];
				}
			}
			if (value === void 0 || value === 'null') {
				value = null;
			}
			this._options.afterGetState(key, value);
			return value;
		};

		Tour.prototype._showNextStep = function () {
			var promise,
			showNextStepHelper,
			step;
			step = this.getStep(this._current);
			
			showNextStepHelper = (function (_this) {
				return function (e) {
					return _this.showStep(step.next);
				};
			})(this);
			
			promise = void 0;

			if (step.onNext != null)
			{
				rslt = step.onNext(this);
				
				if(rslt === false)
				{
					return this.showStep(this._current);
				}
				
				promise = this._makePromise(rslt);
			}

			return this._callOnPromiseDone(promise, showNextStepHelper);
		};

		Tour.prototype._showPrevStep = function () {
			var promise,
			showPrevStepHelper,
			step;
			step = this.getStep(this._current);			
			showPrevStepHelper = (function (_this) {
				return function (e) {
					return _this.showStep(step.prev);
				};
			})(this);
			
			promise = void 0;

			if (step.onPrev != null)
			{
				rslt = step.onPrev(this);
				
				if(rslt === false)
				{
					return this.showStep(this._current);
				}
				
				promise = this._makePromise(rslt);
			}

			return this._callOnPromiseDone(promise, showPrevStepHelper);
		};

		Tour.prototype._debug = function (text) {
			if (this._options.debug) {
				return window.console.log("Bootstrap Tour '" + this._options.name + "' | " + text);
			}
		};

		Tour.prototype._isRedirect = function (host, path, location) {
			var currentPath;
			if ((host != null) && host !== '' && (({}
						.toString.call(host) === '[object RegExp]' && !host.test(location.origin)) || ({}
						.toString.call(host) === '[object String]' && this._isHostDifferent(host, location)))) {
				return true;
			}
			currentPath = [location.pathname, location.search, location.hash].join('');
			return (path != null) && path !== '' && (({}
					.toString.call(path) === '[object RegExp]' && !path.test(currentPath)) || ({}
					.toString.call(path) === '[object String]' && this._isPathDifferent(path, currentPath)));
		};

		Tour.prototype._isHostDifferent = function (host, location) {
			switch ({}
				.toString.call(host)) {
			case '[object RegExp]':
				return !host.test(location.origin);
			case '[object String]':
				return this._getProtocol(host) !== this._getProtocol(location.href) || this._getHost(host) !== this._getHost(location.href);
			default:
				return true;
			}
		};

		Tour.prototype._isPathDifferent = function (path, currentPath) {
			return this._getPath(path) !== this._getPath(currentPath) || !this._equal(this._getQuery(path), this._getQuery(currentPath)) || !this._equal(this._getHash(path), this._getHash(currentPath));
		};

		Tour.prototype._isJustPathHashDifferent = function (host, path, location) {
			var currentPath;
			if ((host != null) && host !== '') {
				if (this._isHostDifferent(host, location)) {
					return false;
				}
			}
			currentPath = [location.pathname, location.search, location.hash].join('');
			if ({}
				.toString.call(path) === '[object String]') {
				return this._getPath(path) === this._getPath(currentPath) && this._equal(this._getQuery(path), this._getQuery(currentPath)) && !this._equal(this._getHash(path), this._getHash(currentPath));
			}
			return false;
		};

		Tour.prototype._redirect = function (step, i, path) {
			var href;
			if ($.isFunction(step.redirect)) {
				return step.redirect.call(this, path);
			} else {
				href = {}
				.toString.call(step.host) === '[object String]' ? "" + step.host + path : path;
				this._debug("Redirect to " + href);
				if (this._getState('redirect_to') === ("" + i)) {
					this._debug("Error redirection loop to " + path);
					this._removeState('redirect_to');
					if (step.onRedirectError != null) {
						return step.onRedirectError(this);
					}
				} else {
					this._setState('redirect_to', "" + i);
					return document.location.href = href;
				}
			}
		};

		Tour.prototype._isOrphan = function (step) {
			return (step.element == null) || !$(step.element).length || $(step.element).is(':hidden') && ($(step.element)[0].namespaceURI !== 'http://www.w3.org/2000/svg');
		};

		Tour.prototype._isLast = function () {
			return this._current < this._options.steps.length - 1;
		};

		Tour.prototype._showPopoverAndOverlay = function (i) {
			var step;
			if (this.getCurrentStep() !== i || this.ended()) {
				return;
			}
			step = this.getStep(i);
			if (step.backdrop) {
				this._showOverlayElement(step);
			}
			this._showPopover(step, i);
			
			this._fixBootstrapSelectPickerZindex(step);
			
			if (step.onShown != null) {
				step.onShown(this);
			}
			return this;
		};

		Tour.prototype._showPopover = function (step, i) {
			var $element,
			$tip,
			isOrphan,
			options,
			shouldAddSmart,
			title,
			content, 
			percentProgress,
			modalObject;
			
			// is this step already visible?
			if($(document).find(".popover.tour-" + this._options.name + ".tour-" + this._options.name + "-" + i).length == 0)
			{
				$(".tour-" + this._options.name).remove();
				options = $.extend({}, this._options);
				isOrphan = this._isOrphan(step);
				step.template = this._template(step, i);
				
				if (isOrphan)
				{
					step.element = 'body';
					step.placement = 'top';
				}
				
				$element = $(step.element);

				$modalObject = null;
				
				// is element a modal?
				if(!isOrphan && ($element.hasClass("modal") || $element.data('bs.modal')))
				{
					$modalObject = $element;
					
					// fix the element, the actual visible offset comes from modal > modal-dialog > modal-content and $element is used to calc this offset & size
					$element = $(step.element).find(".modal-content");
				}		
				else
				{
					$element = $(step.element);
				}
				
				$element.addClass("tour-" + this._options.name + "-element tour-" + this._options.name + "-" + i + "-element");
				if (step.options) {
					$.extend(options, step.options);
				}
				if (step.reflex && !isOrphan)
				{
					$(step.reflexElement).addClass('tour-step-element-reflex').off((this._reflexEvent(step.reflex)) + ".tour-" + this._options.name).on((this._reflexEvent(step.reflex)) + ".tour-" + this._options.name, (function (_this) {
							return function () {
								if (_this._isLast()) {
									return _this.next();
								} else {
									return _this.end();
								}
							};
						})(this));
				}

				
				// is element inside a modal?
				if($element.parents().hasClass("modal:first").length)
				{
					$modalObject = $element.parents().hasClass("modal:first");
				}
				
				var funcModalHelper = 	function(_this, $_modalObject)
										{
											return function ()
											{
												_this._debug("Modal close triggered");
												
												if(typeof(step.onModalHidden) == "function")
												{
													// if step onModalHidden returns false, do nothing. int, move to the step specified. Otherwise continue regular next/end functionality
													var rslt; 
													
													rslt = step.onModalHidden(_this, i);
													
													if(rslt === false)
													{
														_this._debug("onModalHidden returned exactly false, tour step unchanged");
														return;
													}
													
													if(Number.isInteger(rslt))
													{
														_this._debug("onModalHidden returned int, tour moving to step " + rslt + 1);
														
														$_modalObject.off("hidden.bs.modal", funcModalHelper);
														return _this.goTo(rslt);
													}
												}
												
												$_modalObject.off("hidden.bs.modal", funcModalHelper);

												if (_this._isLast())
												{
													return _this.next();
												}
												else
												{
													return _this.end();
												}
											};
										}(this, $modalObject);
				
				if($modalObject)
				{
					$modalObject.off("hidden.bs.modal", funcModalHelper).on("hidden.bs.modal", funcModalHelper);		
				}
				
				

				shouldAddSmart = step.smartPlacement === true && step.placement.search(/auto/i) === -1;
				
				title = step.title;
				content = step.content;
				percentProgress = parseInt(((i + 1) / this.getStepCount()) * 100);
				
				if(step.showProgressBar)
				{
					if(typeof(step.getProgressBarHTML) == "function")
					{
						content = step.getProgressBarHTML(percentProgress) + content;
					}
					else
					{
						content = '<div class="progress"><div class="progress-bar progress-bar-striped" role="progressbar" style="width: ' + percentProgress + '%;"></div></div>' + content;	
					}
				}
				
				if(step.showProgressText)
				{
					if(typeof(step.getProgressTextHTML) == "function")
					{
						title += step.getProgressTextHTML(i, percentProgress, this.getStepCount());
					}
					else
					{
						title += '<span class="pull-right">' + (i + 1) + '/' + this.getStepCount() + '</span>';
					}
				}
				
				$element.popover({
					placement: shouldAddSmart ? "auto " + step.placement : step.placement,
					trigger: 'manual',
					title: title,
					content: content,
					html: true,
					animation: step.animation,
					container: step.container,
					template: step.template,
					selector: step.element
				}).popover('show');
							
				$tip = $element.data('bs.popover') ? $element.data('bs.popover').tip() : $element.data('popover').tip();
				$tip.attr('id', step.id);
				if ($element.css('position') === 'fixed') {
					$tip.css('position', 'fixed');
				}
				
				this._debug("Step " + (this._current + 1) + " of " + this._options.steps.length);
			}
			else
			{
				if (this._isOrphan(step))
				{
					step.element = 'body';
					step.placement = 'top';
				}

				$element = $(step.element);
				$tip = $element.data('bs.popover') ? $element.data('bs.popover').tip() : $element.data('popover').tip();
			}
			
			if (isOrphan)
			{
				return this._center($tip);
			}
			else
			{
				return this._reposition($tip, step);
			}
		};

		Tour.prototype._template = function (step, i) {
			var $navigation,
			$next,
			$prev,
			$resume,
			$template,
			template;
			template = step.template;
			if (this._isOrphan(step) && {}
				.toString.call(step.orphan) !== '[object Boolean]') {
				template = step.orphan;
			}
			$template = $.isFunction(template) ? $(template(i, step)) : $(template);
			$navigation = $template.find('.popover-navigation');
			$prev = $navigation.find('[data-role="prev"]');
			$next = $navigation.find('[data-role="next"]');
			$resume = $navigation.find('[data-role="pause-resume"]');
			if (this._isOrphan(step)) {
				$template.addClass('orphan');
			}
			$template.addClass("tour-" + this._options.name + " tour-" + this._options.name + "-" + i);
			if (step.reflex) {
				$template.addClass("tour-" + this._options.name + "-reflex");
			}
			if (step.prev < 0) {
				$prev.addClass('disabled').prop('disabled', true).prop('tabindex', -1);
			}
			if (step.next < 0) {
				$next.addClass('disabled').prop('disabled', true).prop('tabindex', -1);
			}
			if (step.reflexOnly && step.reflex) {
				$next.hide();
			}
			if (!step.duration) {
				$resume.remove();
			}
			return $template.clone().wrap('<div>').parent().html();
		};

		Tour.prototype._reflexEvent = function (reflex) {
			if ({}
				.toString.call(reflex) === '[object Boolean]') {
				return 'click';
			} else {
				return reflex;
			}
		};

		Tour.prototype._reposition = function ($tip, step) {
			var offsetBottom,
			offsetHeight,
			offsetRight,
			offsetWidth,
			originalLeft,
			originalTop,
			tipOffset;
			offsetWidth = $tip[0].offsetWidth;
			offsetHeight = $tip[0].offsetHeight;
			
			tipOffset = $tip.offset();
			originalLeft = tipOffset.left;
			originalTop = tipOffset.top;
			
			offsetBottom = $(document).height() - tipOffset.top - $tip.outerHeight();
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

		Tour.prototype._center = function ($tip) {
			return $tip.css('top', $(window).outerHeight() / 2 - $tip.outerHeight() / 2);
		};

		Tour.prototype._replaceArrow = function ($tip, delta, dimension, position) {
			return $tip.find('.arrow').css(position, delta ? 50 * (1 - delta / dimension) + '%' : '');
		};

		Tour.prototype._scrollIntoView = function (i) {
			var $element,
			$window,
			counter,
			height,
			offsetTop,
			scrollTop,
			step,
			windowHeight;
			step = this.getStep(i);
			$element = $(step.element);
			if (!$element.length) {
				return this._showPopoverAndOverlay(i);
			}
			$window = $(window);
			offsetTop = $element.offset().top;
			height = $element.outerHeight();
			windowHeight = $window.height();
			scrollTop = 0;
			switch (step.placement) {
			case 'top':
				scrollTop = Math.max(0, offsetTop - (windowHeight / 2));
				break;
			case 'left':
			case 'right':
				scrollTop = Math.max(0, (offsetTop + height / 2) - (windowHeight / 2));
				break;
			case 'bottom':
				scrollTop = Math.max(0, (offsetTop + height) - (windowHeight / 2));
			}
			this._debug("Scroll into view. ScrollTop: " + scrollTop + ". Element offset: " + offsetTop + ". Window height: " + windowHeight + ".");
			counter = 0;
			return $('body, html').stop(true, true).animate({
				scrollTop: Math.ceil(scrollTop)
			}, (function (_this) {
					return function () {
						if (++counter === 2) {
							_this._showPopoverAndOverlay(i);
							return _this._debug("Scroll into view.\nAnimation end element offset: " + ($element.offset().top) + ".\nWindow height: " + ($window.height()) + ".");
						}
					};
				})(this));
		};

		Tour.prototype._onResize = function (callback, timeout) {
			return $(window).on("resize.tour-" + this._options.name, function () {
				clearTimeout(timeout);
				return timeout = setTimeout(callback, 100);
			});
		};

		Tour.prototype._onScroll = function (callback, timeout) {
			return $(window).on("scroll.tour-" + this._options.name, function () {
				clearTimeout(timeout);
				return timeout = setTimeout(callback, 100);
			});
		};

		Tour.prototype._initMouseNavigation = function () {
			var _this;
			_this = this;
			return $(document).off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='prev']").off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='next']").off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='end']").off("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='pause-resume']").on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='next']", (function (_this) {
					return function (e) {
						e.preventDefault();
						return _this.next();
					};
				})(this)).on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='prev']", (function (_this) {
					return function (e) {
						e.preventDefault();
						if (_this._current > 0) {
							return _this.prev();
						}
					};
				})(this)).on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='end']", (function (_this) {
					return function (e) {
						e.preventDefault();
						return _this.end();
					};
				})(this)).on("click.tour-" + this._options.name, ".popover.tour-" + this._options.name + " *[data-role='pause-resume']", function (e) {
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

		Tour.prototype._initKeyboardNavigation = function () {
			if (!this._options.keyboard) {
				return;
			}
			return $(document).on("keyup.tour-" + this._options.name, (function (_this) {
					return function (e) {
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
							if (_this._current > 0) {
								return _this.prev();
							}
						}
					};
				})(this));
		};

		Tour.prototype._makePromise = function (result) {
			if (result && $.isFunction(result.then)) {
				return result;
			} else {
				return null;
			}
		};

		Tour.prototype._callOnPromiseDone = function (promise, cb, arg) {
			if (promise) {
				return promise.then(
										(function (_this)
										{
											return function (e)
											{
												return cb.call(_this, arg);
											};
										}
										)(this)
									);
			} else {
				return cb.call(this, arg);
			}
		};

		// Bootstrap Select custom draws the drop down, force the Z index between Tour overlay and popoper
 		Tour.prototype._fixBootstrapSelectPickerZindex = function(step)
		{
			if(!this._isOrphan(step))
			{
				// is this element or child of this element a selectpicker
				if($(step.element)[0].tagName.toLowerCase() == "select")
				{
					$selectpicker = $(step.element);
				}
				else
				{
					$selectpicker = $(step.element).find("select:first");
				}
				
				// is this selectpicker a bootstrap-select: https://github.com/snapappointments/bootstrap-select/ 
				if($selectpicker.parent().hasClass("bootstrap-select"))
				{
					// set zindex to open dropdown over background element
					$selectpicker.parent().css("z-index", "1101");
				}
			}			
		}		

		
		Tour.prototype._showBackground = function (step, data) {
			var $backdrop,
			base,
			height,
			j,
			len,
			pos,
			ref,
			results,
			width;
			
			height = $(document).height();
			width = $(document).width();
			ref = ['top', 'bottom', 'left', 'right'];
			results = [];
		
			
			for (j = 0, len = ref.length; j < len; j++) {
				pos = ref[j];
				$backdrop = (base = this.backdrops)[pos] != null ? base[pos] : base[pos] = $('<div>', {
						"class": "tour-backdrop " + pos
					});
				$(step.backdropContainer).append($backdrop);
				switch (pos) {
				case 'top':
					results.push($backdrop.height(data.offset.top > 0 ? data.offset.top : 0).width(width).offset({
							top: 0,
							left: 0
						}));
					break;
				case 'bottom':
					results.push($backdrop.offset({
							top: data.offset.top + data.height,
							left: 0
						}).height(height - (data.offset.top + data.height)).width(width));
					break;
				case 'left':
					results.push($backdrop.offset({
							top: data.offset.top,
							left: 0
						}).height(data.height).width(data.offset.left > 0 ? data.offset.left : 0));
					break;
				case 'right':
					results.push($backdrop.offset({
							top: data.offset.top,
							left: data.offset.left + data.width
						}).height(data.height).width(width - (data.offset.left + data.width)));
					break;
				default:
					results.push(void 0);
				}
			}
			
			return results;
		};

		Tour.prototype._showOverlayElement = function (step) {
			var $backdropElement,
			elementData;
			
			if(step.preventInteraction)
			{
				$(step.backdropContainer).append("<div class='tour-prevent' id='tourPrevent'></div>");
				$("#tourPrevent").width($(step.element).outerWidth());
				$("#tourPrevent").height($(step.element).outerHeight());
				$("#tourPrevent").offset($(step.element).offset());
			}
			
			$backdropElement = $(step.backdropElement);
			if ($backdropElement.length === 0)
			{
				elementData = {
					width: 0,
					height: 0,
					offset: {
						top: 0,
						left: 0
					}
				};
			}
			else
			{
				elementData = {
					width: $backdropElement.innerWidth(),
					height: $backdropElement.innerHeight(),
					offset: $backdropElement.offset()
				};
				$backdropElement.addClass('tour-step-backdrop');
				if (step.backdropPadding) {
					elementData = this._applyBackdropPadding(step.backdropPadding, elementData);
				}
			}
			
			return this._showBackground(step, elementData);
		};

		Tour.prototype._hideOverlayElement = function (step) {
			var $backdrop,
			pos,
			ref;
			
			// remove any previous interaction overlay
			if($("#tourPrevent").length)
				$("#tourPrevent").remove();

			$(step.backdropElement).removeClass('tour-step-backdrop');
			ref = this.backdrops;
			for (pos in ref) {
				$backdrop = ref[pos];
				if ($backdrop && $backdrop.remove !== void 0) {
					$backdrop.remove();
				}
			}
			return this.backdrops = [];
		};

		Tour.prototype._applyBackdropPadding = function (padding, data) {
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

		Tour.prototype._clearTimer = function () {
			window.clearTimeout(this._timer);
			this._timer = null;
			return this._duration = null;
		};

		Tour.prototype._getProtocol = function (url) {
			url = url.split('://');
			if (url.length > 1) {
				return url[0];
			} else {
				return 'http';
			}
		};

		Tour.prototype._getHost = function (url) {
			url = url.split('//');
			url = url.length > 1 ? url[1] : url[0];
			return url.split('/')[0];
		};

		Tour.prototype._getPath = function (path) {
			return path.replace(/\/?$/, '').split('?')[0].split('#')[0];
		};

		Tour.prototype._getQuery = function (path) {
			return this._getParams(path, '?');
		};

		Tour.prototype._getHash = function (path) {
			return this._getParams(path, '#');
		};

		Tour.prototype._getParams = function (path, start) {
			var j,
			len,
			param,
			params,
			paramsObject;
			params = path.split(start);
			if (params.length === 1) {
				return {};
			}
			params = params[1].split('&');
			paramsObject = {};
			for (j = 0, len = params.length; j < len; j++) {
				param = params[j];
				param = param.split('=');
				paramsObject[param[0]] = param[1] || '';
			}
			return paramsObject;
		};

		Tour.prototype._equal = function (obj1, obj2) {
			var j,
			k,
			len,
			obj1Keys,
			obj2Keys,
			v;
			if ({}
				.toString.call(obj1) === '[object Object]' && {}
				.toString.call(obj2) === '[object Object]') {
				obj1Keys = Object.keys(obj1);
				obj2Keys = Object.keys(obj2);
				if (obj1Keys.length !== obj2Keys.length) {
					return false;
				}
				for (k in obj1) {
					v = obj1[k];
					if (!this._equal(obj2[k], v)) {
						return false;
					}
				}
				return true;
			} else if ({}
				.toString.call(obj1) === '[object Array]' && {}
				.toString.call(obj2) === '[object Array]') {
				if (obj1.length !== obj2.length) {
					return false;
				}
				for (k = j = 0, len = obj1.length; j < len; k = ++j) {
					v = obj1[k];
					if (!this._equal(v, obj2[k])) {
						return false;
					}
				}
				return true;
			} else {
				return obj1 === obj2;
			}
		};

		return Tour;

	})();
	return Tour;
});

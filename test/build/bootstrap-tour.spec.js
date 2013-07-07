(function() {
  describe("Bootstrap Tour", function() {
    afterEach(function() {
      this.tour.setState("current_step", null);
      this.tour.setState("end", null);
      return $.each(this.tour._steps, function(i, s) {
        if ((s.element != null) && (s.element.popover != null)) {
          return s.element.popover("hide").removeData("popover");
        }
      });
    });
    it("should set the tour options", function() {
      this.tour = new Tour({
        name: "test",
        afterSetState: function() {
          return true;
        },
        afterGetState: function() {
          return true;
        }
      });
      expect(this.tour._options.name).toBe("test");
      expect(this.tour._options.afterGetState).toBeTruthy;
      return expect(this.tour._options.afterSetState).toBeTruthy;
    });
    it("should have default name of 'tour'", function() {
      this.tour = new Tour;
      return expect(this.tour._options.name).toBe("tour");
    });
    it("should accept an array of steps and set the current step", function() {
      this.tour = new Tour;
      expect(this.tour._steps).toEqual([]);
      return expect(this.tour._current).toBe(0);
    });
    it("'setState' should save state cookie", function() {
      this.tour = new Tour;
      this.tour.setState("save", "yes");
      expect($.cookie("tour_save")).toBe("yes");
      return $.removeCookie("tour_save");
    });
    it("'getState' should get state cookie", function() {
      this.tour = new Tour;
      this.tour.setState("get", "yes");
      expect(this.tour.getState("get")).toBe("yes");
      return $.removeCookie("tour_get");
    });
    it("'setState' should save state localStorage items", function() {
      this.tour = new Tour({
        useLocalStorage: true
      });
      this.tour.setState("test", "yes");
      return expect(window.localStorage.getItem("tour_test")).toBe("yes");
    });
    it("'getState' should get state localStorage items", function() {
      this.tour = new Tour({
        useLocalStorage: true
      });
      this.tour.setState("test", "yes");
      expect(this.tour.getState("test")).toBe("yes");
      return window.localStorage.setItem("tour_test", null);
    });
    it("'addStep' should add a step", function() {
      var step;
      this.tour = new Tour;
      step = {
        element: $("<div></div>").appendTo("body")
      };
      this.tour.addStep(step);
      return expect(this.tour._steps).toEqual([step]);
    });
    it("'addSteps' should add multiple step", function() {
      var firstStep, secondStep;
      this.tour = new Tour;
      firstStep = {
        element: $("<div></div>").appendTo("body")
      };
      secondStep = {
        element: $("<div></div>").appendTo("body")
      };
      this.tour.addSteps([firstStep, secondStep]);
      return expect(this.tour._steps).toEqual([firstStep, secondStep]);
    });
    it("step should have an id", function() {
      var $element;
      this.tour = new Tour;
      $element = $("<div></div>").appendTo("body");
      this.tour.addStep({
        element: $element
      });
      this.tour.start();
      return expect($element.data("popover").tip().attr("id")).toBe("step-0");
    });
    it("with 'onStart' option should run the callback before showing the first step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onStart: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      return expect(tour_test).toBe(2);
    });
    it("with 'onEnd' option should run the callback after hiding the last step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onEnd: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.end();
      return expect(tour_test).toBe(2);
    });
    it("with 'onShow' option should run the callback before showing the step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onShow: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      expect(tour_test).toBe(2);
      this.tour.next();
      return expect(tour_test).toBe(4);
    });
    it("with 'onShown' option should run the callback after showing the step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onShown: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      return expect(tour_test).toBe(2);
    });
    it("with 'onHide' option should run the callback before hiding the step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onHide: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      expect(tour_test).toBe(2);
      this.tour.hideStep(1);
      return expect(tour_test).toBe(4);
    });
    it(" with onHidden option should run the callback after hiding the step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onHidden: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      expect(tour_test).toBe(2);
      this.tour.next();
      return expect(tour_test).toBe(4);
    });
    it(".addStep with onShow option should run the callback before showing the step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        onShow: function() {
          return tour_test = 2;
        }
      });
      this.tour.start();
      expect(tour_test).toBe(0);
      this.tour.next();
      return expect(tour_test).toBe(2);
    });
    it(".addStep with onHide option should run the callback before hiding the step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        onHide: function() {
          return tour_test = 2;
        }
      });
      this.tour.start();
      this.tour.next();
      expect(tour_test).toBe(0);
      this.tour.hideStep(1);
      return expect(tour_test).toBe(2);
    });
    it("'getStep' should get a step", function() {
      var step;
      this.tour = new Tour;
      step = {
        element: $("<div></div>").appendTo("body"),
        container: "body",
        path: "test",
        placement: "left",
        title: "Test",
        content: "Just a test",
        id: "step-0",
        prev: -1,
        next: 2,
        end: false,
        animation: false,
        backdrop: false,
        redirect: true,
        onShow: function(tour) {},
        onShown: function(tour) {},
        onHide: function(tour) {},
        onHidden: function(tour) {},
        onNext: function(tour) {},
        onPrev: function(tour) {},
        template: "<div class='popover tour'>      <div class='arrow'></div>      <h3 class='popover-title'></h3>      <div class='popover-content'></div>      </div>"
      };
      this.tour.addStep(step);
      return expect(this.tour.getStep(0)).toEqual(step);
    });
    it("'start' should start a tour", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      return expect($(".popover").length).toBe(1);
    });
    it("'start' should not start a tour that ended", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.setState("end", "yes");
      this.tour.start();
      return expect($(".popover").length).toBe(0);
    });
    it("'start'(true) should force starting a tour that ended", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.setState("end", "yes");
      this.tour.start(true);
      return expect($(".popover").length).toBe(1);
    });
    it("'next' should hide current step and show next step", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      expect(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length).toBe(0);
      return expect(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("'end' should hide current step and set end state", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.end();
      expect(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length).toBe(0);
      return expect(this.tour.getState("end")).toBe("yes");
    });
    it("'ended' should return true is tour ended and false if not", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      expect(this.tour.ended()).toBe(false);
      this.tour.end();
      return expect(this.tour.ended()).toBe(true);
    });
    it("'restart' should clear all states and start tour", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      this.tour.end();
      this.tour.restart();
      expect(this.tour.getState("end")).toBe(null);
      expect(this.tour._current).toBe(0);
      return expect($(".popover").length).toBe(1);
    });
    it("'hideStep' should hide a step", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.hideStep(0);
      return expect(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length).toBe(0);
    });
    it("'showStep' should set a step and show it", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.showStep(1);
      expect(this.tour._current).toBe(1);
      expect($(".popover").length).toBe(1);
      return expect(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("'showStep' should not show anything when the step doesn't exist", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.showStep(2);
      return expect($(".popover").length).toBe(0);
    });
    it("'showStep' should skip step when no element is specified", function() {
      this.tour = new Tour;
      this.tour.addStep({});
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.showStep(1);
      return expect(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("'showStep' should skip step when element doesn't exist", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: "#tour-test"
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.showStep(1);
      return expect(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("'showStep' should skip step when element is invisible", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body").hide()
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.showStep(1);
      return expect(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("'setCurrentStep' should set the current step", function() {
      this.tour = new Tour;
      this.tour.setCurrentStep(4);
      expect(this.tour._current).toBe(4);
      this.tour.setState("current_step", 2);
      this.tour.setCurrentStep();
      return expect(this.tour._current).toBe(2);
    });
    it("'showNextStep' should show the next step", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.showNextStep();
      return expect(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("'showPrevStep' should show the previous step", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.showStep(1);
      this.tour.showPrevStep();
      return expect(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("'showStep' should show multiple step on the same element", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      expect(this.tour.getStep(0).element.data("popover").tip().filter(":visible").length).toBe(1);
      this.tour.showNextStep();
      return expect(this.tour.getStep(1).element.data("popover").tip().filter(":visible").length).toBe(1);
    });
    it("properly verify paths", function() {
      this.tour = new Tour;
      expect(this.tour._isRedirect(void 0, "/")).toBe(false);
      expect(this.tour._isRedirect("", "/")).toBe(false);
      expect(this.tour._isRedirect("/somepath", "/somepath")).toBe(false);
      expect(this.tour._isRedirect("/somepath/", "/somepath")).toBe(false);
      expect(this.tour._isRedirect("/somepath", "/somepath/")).toBe(false);
      expect(this.tour._isRedirect("/somepath?search=true", "/somepath")).toBe(false);
      expect(this.tour._isRedirect("/somepath/?search=true", "/somepath")).toBe(false);
      return expect(this.tour._isRedirect("/anotherpath", "/somepath")).toBe(true);
    });
    it("'getState' should return null after Tour.removeState with null value using cookies", function() {
      this.tour = new Tour({
        useLocalStorage: false
      });
      this.tour.setState("test", "test");
      this.tour.removeState("test");
      return expect(this.tour.getState("test")).toBe(null);
    });
    it("'getState' should return null after Tour.removeState with null value using localStorage", function() {
      this.tour = new Tour({
        useLocalStorage: true
      });
      this.tour.setState("test", "test");
      this.tour.removeState("test");
      return expect(this.tour.getState("test")).toBe(null);
    });
    it("'removeState' should call afterRemoveState callback", function() {
      var sentinel;
      sentinel = false;
      this.tour = new Tour({
        afterRemoveState: function() {
          return sentinel = true;
        }
      });
      this.tour.removeState("current_step");
      return expect(sentinel).toBe(true);
    });
    it("shouldn't move to the next state until the onShow promise is resolved", function() {
      var deferred;
      this.tour = new Tour;
      deferred = $.Deferred();
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        onShow: function() {
          return deferred;
        }
      });
      this.tour.start();
      this.tour.next();
      expect(this.tour._current).toBe(0);
      deferred.resolve();
      return expect(this.tour._current).toBe(1);
    });
    it("shouldn't hide popover until the onHide promise is resolved", function() {
      var deferred;
      this.tour = new Tour;
      deferred = $.Deferred();
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        onHide: function() {
          return deferred;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      expect(this.tour._current).toBe(0);
      deferred.resolve();
      return expect(this.tour._current).toBe(1);
    });
    it("shouldn't start until the onStart promise is resolved", function() {
      var deferred;
      deferred = $.Deferred();
      this.tour = new Tour({
        onStart: function() {
          return deferred;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      expect($(".popover").length).toBe(0);
      deferred.resolve();
      return expect($(".popover").length).toBe(1);
    });
    it("'reflex' parameter should change the element cursor to pointer when the step is displayed", function() {
      var $element;
      $element = $("<div></div>").appendTo("body");
      this.tour = new Tour;
      this.tour.addStep({
        element: $element,
        reflex: true
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      expect($element.css("cursor")).toBe("auto");
      this.tour.start();
      expect($element.css("cursor")).toBe("pointer");
      this.tour.next();
      return expect($element.css("cursor")).toBe("auto");
    });
    it("'showStep' redirects to the anchor when the path is an anchor", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        path: "#mytest"
      });
      this.tour.showStep(0);
      expect(document.location.hash).toBe("#mytest");
      return document.location.hash = "";
    });
    it("'backdrop' parameter should show backdrop with step", function() {
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        backdrop: false
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        backdrop: true
      });
      this.tour.showStep(0);
      expect($(".tour-backdrop").length).toBe(0);
      expect($(".tour-step-backdrop").length).toBe(0);
      expect($(".tour-step-background").length).toBe(0);
      this.tour.showStep(1);
      expect($(".tour-backdrop").length).toBe(1);
      expect($(".tour-step-backdrop").length).toBe(1);
      expect($(".tour-step-background").length).toBe(1);
      this.tour.end();
      expect($(".tour-backdrop").length).toBe(0);
      expect($(".tour-step-backdrop").length).toBe(0);
      return expect($(".tour-step-background").length).toBe(0);
    });
    it("'basePath' should prepend the path to the steps", function() {
      this.tour = new Tour({
        basePath: 'test/'
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        path: 'test.html'
      });
      return expect(this.tour._isRedirect(this.tour._options.basePath + this.tour.getStep(0).path, 'test/test.html')).toBe(false);
    });
    it("with 'onNext' option should run the callback before showing the next step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onNext: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      return expect(tour_test).toBe(2);
    });
    it("'addStep' with onNext option should run the callback before showing the next step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        onNext: function() {
          return tour_test = 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      expect(tour_test).toBe(0);
      this.tour.next();
      return expect(tour_test).toBe(2);
    });
    it("with 'onPrev' option should run the callback before showing the prev step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour({
        onPrev: function() {
          return tour_test += 2;
        }
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      this.tour.prev();
      return expect(tour_test).toBe(2);
    });
    it("Tour.addStep with onPrev option should run the callback before showing the prev step", function() {
      var tour_test;
      tour_test = 0;
      this.tour = new Tour;
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body"),
        onPrev: function() {
          return tour_test = 2;
        }
      });
      this.tour.start();
      expect(tour_test).toBe(0);
      this.tour.next();
      this.tour.prev();
      return expect(tour_test).toBe(2);
    });
    it("should render custom navigation template", function() {
      this.tour = new Tour({
        template: "<div class='popover tour'>          <div class='arrow'></div>          <h3 class='popover-title'></h3>          <div class='popover-content'></div>          <div class='popover-navigation'>            <a data-role='prev'></a>            <a data-role='next'></a>            <a data-role='end'></a>          </div>        </div>"
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      this.tour.start();
      this.tour.next();
      return expect($(".popover .popover-navigation a").length).toBe(3);
    });
    it("should have 'data-role' attribute for navigation template", function() {
      var template;
      this.tour = new Tour;
      template = $(this.tour._options.template);
      expect(template.find("*[data-role=next]").size()).toBe(1);
      expect(template.find("*[data-role=prev]").size()).toBe(1);
      expect(template.find("*[data-role=separator]").size()).toBe(1);
      return expect(template.find("*[data-role=end]").size()).toBe(1);
    });
    return it("should unbind click events when hiding step (in reflex mode)", function() {
      var $element,
        _this = this;
      $element = $("<div></div>").appendTo("body");
      this.tour = new Tour;
      this.tour.addStep({
        element: $element,
        reflex: true
      });
      this.tour.addStep({
        element: $("<div></div>").appendTo("body")
      });
      expect($._data($element[0], "events")).not.toBeDefined();
      this.tour.start();
      expect($._data($element[0], "events").click.length).toBeGreaterThan(0);
      expect($._data($element[0], "events").click[0].namespace).toBe("bootstrap-tour");
      return $.each([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], function() {
        _this.tour.next();
        expect($._data($element[0], "events")).not.toBeDefined();
        _this.tour.prev();
        expect($._data($element[0], "events").click.length).toBeGreaterThan(0);
        return expect($._data($element[0], "events").click[0].namespace).toBe("bootstrap-tour");
      });
    });
  });

}).call(this);

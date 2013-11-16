$(function() {
  var $start, tour;
  $start = $("#start");
  tour = new Tour({
    onStart: function() {
      return $start.addClass("disabled", true);
    },
    onEnd: function() {
      return $start.removeClass("disabled", true);
    },
    backdrop: true,
    debug: true
  });
  tour.addSteps([
    {
      element: "#download",
      placement: "bottom",
      title: "Welcome to Bootstrap Tour!",
      content: "Introduce new users to your product by walking them through it step by step. Built" + "on the awesome <a href='http://twitter.github.com/bootstrap' target='_blank'>Bootstrap " + "from Twitter.</a>"
    }, {
      element: "#usage",
      placement: "top",
      title: "Setup in four easy steps",
      content: "Easy is better, right? Easy like Bootstrap."
    }, {
      element: "#options",
      placement: "top",
      title: "And it is powerful!",
      content: "There are more options for those, like us, who want to do complicated things. " + "<br />Power to the people! :P",
      reflex: true
    }, {
      element: "#demo",
      placement: "top",
      title: "A new shiny Backdrop option",
      content: "If you need to highlight the current step's element, activate the backdrop " + "and you won't lose the focus anymore!",
      backdrop: true
    }, {
      title: "And support for orphan steps",
      content: "If you activate the orphan property, the step(s) are shown centered " + "in the page, and you can forget to specify element and placement!",
      orphan: true
    }, {
      path: "/",
      element: "#reflex",
      placement: "bottom",
      title: "Reflex mode",
      content: "Reflex mode is enabled, click on the page heading to continue!",
      reflex: true
    }, {
      path: "/page.html",
      element: "h1",
      placement: "bottom",
      title: "See, you are not restricted to only one page",
      content: "Well, nothing to see here. Click next to go back to the index page."
    }, {
      path: "/",
      element: "#license",
      placement: "top",
      title: "Best of all, it's free!",
      content: "Yeah! Free as in beer... or speech. Use and abuse, but don't forget to contribute!"
    }
  ]);
  tour.start();
  if (tour.ended()) {
    $('<div class="alert alert-warning"><button class="close" data-dismiss="alert">&times;</button>You ended the demo tour. <a href="#" class="start">Restart the demo tour.</a></div>').prependTo(".content").alert();
  }
  $(document).on("click", ".start", function(e) {
    e.preventDefault();
    if ($(this).hasClass("disabled")) {
      return;
    }
    tour.restart();
    return $(".alert").alert("close");
  });
  return $("html").smoothScroll();
});

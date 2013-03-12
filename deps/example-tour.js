
jQuery(function($) {
  var tour = new Tour();
  tour.addStep({
    element: "#overview",
    placement: "bottom",
    title: "Welcome to Bootstrap Tour!",
    content: "Introduce new users to your product by walking them "
    + "through it step by step. Built on the awesome "
    + "<a href='http://twitter.github.com/bootstrap' target='_blank'>"
    + "Bootstrap from Twitter.<\/a>"
  });
  tour.addStep({
    element: "#usage",
    placement: "right",
    title: "Setup in four easy steps",
    content: "Easy is better, right? Easy like Bootstrap.",
    options: {
      labels: {prev: "Go back", next: "Hey", end: "Stop"}
    }
  });
  tour.addStep({
    path: "/",
    element: "#options",
    placement: "right",
    title: "And it is powerful!",
    content: "There are more options for those, like us, who want to do "
    + "complicated things. <br \/>Power to the people! :P",
    reflex: true
  });
  tour.addStep({
    path: "/",
    element: "#reflex-mode",
    placement: "bottom",
    title: "Reflex mode",
    content: "Reflex mode is enabled, click on the page heading to continue!",
    reflex: true
  });
  tour.addStep({
    path: "/page.html",
    element: "h1",
    placement: "bottom",
    title: "See, you are not restricted to only one page",
    content: "Well, nothing to see here. Click next to go back "
    + "to the index page."
  });
  tour.addStep({
    path: "/",
    element: "#contributing",
    placement: "right",
    title: "Best of all, it's free!",
    content: "Yeah! Free as in beer... or speech. Use and abuse, "
    + "but don't forget to contribute!"
  });
  tour.start();

  if ( tour.ended() ) {
    $('<div class="alert">\
      <button class="close" data-dismiss="alert">×</button>\
      You ended the demo tour. <a href="" class="restart">Restart the demo tour.</a>\
      </div>').prependTo(".content").alert();
  }

  $(".restart").click(function (e) {
    e.preventDefault();
    tour.restart();
    $(this).parents(".alert").alert("close");
  });
});

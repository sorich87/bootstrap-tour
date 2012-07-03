
jQuery(function($) {
  var tour = new Tour();
  tour.addStep({
    element: "#overview",
    placement: "bottom",
    title: "Welcome to Bootstrap Tour!",
    content: "Introduce new users to your product by walking them"
    + "through it step by step. Built on the awesome "
    + "<a href='http://twitter.github.com/bootstrap' target='_blank'>"
    + "Bootstrap from Twitter.<\/a>"
  });
  tour.addStep({
    element: "#usage",
    placement: "right",
    title: "Setup in four easy steps",
    content: "Easy is better, right? Easy like Bootstrap."
  });
  tour.addStep({
    element: "#options",
    placement: "right",
    title: "And it is powerful!",
    content: "There are more options for those, like us, who want to do "
    + "complicated things. <br \/>Power to the people! :P"
  });
  tour.addStep({
    path: "test.html",
    element: "h1",
    placement: "bottom",
    title: "See, you are not restricted to only one page",
    content: "Well, nothing to see here. Click next to go back "
    + "to the index page."
  });
  tour.addStep({
    element: "#contributing",
    placement: "right",
    title: "Best of all, it's free!",
    content: "Yeah! Free as in beer... or speech. Use and abuse, "
    + "but don't forget to contribute!"
  });
  tour.start();
});

//


const SPEED = 700;
const MARGIN = 50;

$.easing.easeInOutQuart = (x, t, b, c, d) => {
  if ((t /= d / 2) < 1) {
    return c / 2 * t * t * t * t + b;
  } else {
    return - c / 2 * ((t -= 2) * t * t * t - 2) + b;
  }
};

function prepare() {
  $("a[href^=\"#\"]").on("click", (event) => {
    let href = $(event.target).attr("href");
    let target = $((href == "#") ? "html" : href);
    let modification = $("div.navigation").height() + MARGIN;
    let position = (href == "#") ? 0 : target.offset().top - modification;
    let maxPosition = $(document).height() - $(window).height();
    if (position > maxPosition) {
      position = maxPosition;
    }
    $("html, body").animate({scrollTop: position}, SPEED, "easeInOutQuart");
    return false;
  });
}

$(prepare);
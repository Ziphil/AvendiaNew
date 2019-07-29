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

$.easing.easeInOutQuad = (x, t, b, c, d) => {
  if ((t /= d / 2) < 1) {
    return c / 2 * t * t + b;
  } else {
    return - c / 2 * ((-- t) * (t - 2) - 1) + b;
  }
};

function prepare() {
  $("a[href^=\"#\"]").on("click", (event) => {
    let href = $(event.target).attr("href");
    let target = $((href == "#" || href == "#top") ? "html" : href);
    let position = (href == "#") ? 0 : target.offset().top - MARGIN;
    let maxPosition = $(document).height() - $(window).height();
    if (position < 0) {
      position = 0;
    }
    if (position > maxPosition) {
      position = maxPosition;
    }
    $("html, body").animate({scrollTop: position}, SPEED, "easeInOutQuart");
    return false;
  });
}

$(prepare);
//


const INTERVAL = 5000;
const DURATION = 400;

function prepare() {
  let images = $(".screenshot ul li");
  let firstImage = $(".screenshot ul li:first");
  images.hide();
  firstImage.addClass("active");
  firstImage.show();
  images.on("click", change);
  setInterval(change, INTERVAL);
}

function change() {
  let activeImage = $(".screenshot ul li.active");
  let nextImage = (activeImage.next("li").length) ? activeImage.next("li") : $(".screenshot ul li:first");
  if (!activeImage.is(":animated")) {
    activeImage.removeClass("active");
    activeImage.animate({opacity: "hide"}, DURATION);
    nextImage.addClass("active");
    nextImage.animate({opacity: "show"}, DURATION);
  }
}

$(prepare);
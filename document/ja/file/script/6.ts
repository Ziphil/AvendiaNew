//

import * as query from "jquery";


const SPEED = 700;
const MARGIN = 50;

export function easeInOutQuart(x: number, t: number, b: number, c: number, d: number): number {
  if ((t /= d / 2) < 1) {
    return c / 2 * t * t * t * t + b;
  } else {
    return - c / 2 * ((t -= 2) * t * t * t - 2) + b;
  }
}

export function prepare(): void {
  document.querySelectorAll("a[href^=\"#\"]").forEach((element) => {
    element.addEventListener("click", (event) => {
      let target = <HTMLElement>event.target;
      let href = target.getAttribute("href");
      let position = 0;
      let maxPosition = query(document).height()! - query(window).height()!;
      if (href !== null && href !== "#" && href !== "#top") {
        let after = document.getElementById(href.slice(1));
        if (after !== null) {
          position = query(after).offset()!.top - query("div.navigation").height()! - MARGIN;
        }
      }
      if (position < 0) {
        position = 0;
      }
      if (position > maxPosition) {
        position = maxPosition;
      }
      let body = query("html, body");
      body.animate({scrollTop: position}, SPEED, "easeInOutQuart");
      event.preventDefault();
    });
  });
}

query.easing["easeInOutQuart"] = <any>easeInOutQuart;
window.onload = prepare;
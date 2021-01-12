//

import * as query from "jquery";
import {
  ExecutorBase
} from "./module/executor";


const SPEED = 700;
const MARGIN = 50;


export class Executor extends ExecutorBase {

  protected prepare(): void {
    let gap = query("#navigation").height() ?? 0;
    document.querySelectorAll("a[href^=\"#\"]").forEach((element) => {
      element.addEventListener("click", (event) => {
        let target = event.target as HTMLElement;
        let href = target.getAttribute("href");
        let position = 0;
        let maxPosition = query(document).height()! - query(window).height()!;
        if (href !== null && href !== "#" && href !== "#top") {
          let after = document.getElementById(href.slice(1));
          if (after !== null) {
            position = query(after).offset()!.top - gap - MARGIN;
          }
        }
        if (position < 0) {
          position = 0;
        }
        if (position > maxPosition) {
          position = maxPosition;
        }
        query("html, body").animate({scrollTop: position}, SPEED, "easeInOutQuart");
        event.preventDefault();
      });
    });
  }

}


query.easing["easeInOutQuart"] = function (percent: number, t?: any, b?: any, c?: any, d?: any): number {
  if ((t /= d / 2) < 1) {
    return c / 2 * t * t * t * t + b;
  } else {
    return - c / 2 * ((t -= 2) * t * t * t - 2) + b;
  }
};
//

import {
  ExecutorBase
} from "./module/executor";


export class Executor extends ExecutorBase {

  protected prepare(): void {
    this.fetch("#whole-count", "current", 0);
    this.fetch("#week-count", "difference", 7);
    this.fetch("#month-count", "difference", 30);
  }

  private fetch(query: string, mode: "current" | "difference", day: number): void {
    let request = new XMLHttpRequest();
    let url = this.createUrl(mode, day);
    request.open("GET", url, true);
    request.send(null);
    request.addEventListener("readystatechange", (event) => {
      if (request.readyState === 4 && request.status === 200) {
        let result = request.responseText;
        let element = document.querySelector(query);
        if (element !== null) {
          element.textContent = result;
        }
      }
    });
  }

  private createUrl(mode: "current" | "difference", day: number): string {
    let url = window.location.protocol + "//dic.ziphil.com/api/dictionary";
    if (mode === "current") {
      url += "/count";
    } else {
      url += "/difference?duration=" + day;
    }
    return url;
  }

}


Executor.regsiter();
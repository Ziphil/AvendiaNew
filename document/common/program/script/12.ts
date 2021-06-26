//

import {
  ExecutorBase
} from "./module/executor";


export class Executor extends ExecutorBase {

  protected prepare(): void {
    let request = new XMLHttpRequest();
    let url = window.location.protocol + "//dic.ziphil.com/api/dictionary/difference?durations=7&durations=30&durations=365"
    request.open("GET", url, true);
    request.send(null);
    request.addEventListener("readystatechange", (event) => {
      if (request.readyState === 4 && request.status === 200) {
        let data = JSON.parse(request.responseText);
        for (let {duration, difference} of data.differences) {
          if (duration === 7) {
            document.querySelector("#week-count")!.textContent = Math.max(difference, 0).toString();
          } else if (duration === 30) {
            document.querySelector("#month-count")!.textContent = Math.max(difference, 0).toString();
          } else {
            document.querySelector("#year-count")!.textContent = Math.max(difference, 0).toString();
          }
        }
        document.querySelector("#whole-count")!.textContent = Math.max(data.count, 0).toString();
      }
    });
  }

}


Executor.regsiter();
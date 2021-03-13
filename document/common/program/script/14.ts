//

import {
  ExecutorBase
} from "./module/executor";


export class Executor extends ExecutorBase {

  protected prepare(): void {
    let textArea = document.querySelector<HTMLTextAreaElement>("[name=\"content\"]")!;
    document.querySelector("#submit")!.addEventListener("click", (event) => {
      let request = new XMLHttpRequest();
      let data = new FormData();
      data.append("mode", "request");
      data.append("content", textArea.value);
      request.open("POST", "../../program/interface/3.cgi", true);
      request.send(data);
      request.addEventListener("readystatechange", () => {
        if (request.readyState === 4 && request.status === 200) {
          let result = JSON.parse(request.responseText);
          let size = result.size;
          this.displayResult(size);
        }
      });
      event.preventDefault();
    });
  }

  private displayResult(size: number): void {
    let element = document.querySelector<HTMLDivElement>("#result")!;
    let html = "";
    html += "<h1>依頼完了</h1>\n";
    html += "<p>\n";
    html += `造語依頼が完了しました (${size} 件)。\n`;
    html += "ご協力ありがとうございます。\n";
    html += "</p>\n";
    element.innerHTML = html;
  }

}


Executor.regsiter();
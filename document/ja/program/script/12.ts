//


type DayType = {current: 0, difference: number};


export class Executor {

  public prepare(): void {
    this.fetch("#whole-count", "current", 0);
    this.fetch("#week-count", "difference", 7);
    this.fetch("#month-count", "difference", 30);
  }

  private fetch<M extends keyof DayType>(query: string, mode: M, day: DayType[M]): void {
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

  private createUrl<M extends keyof DayType>(mode: M, day: DayType[M]): string {
    let url = "program/interface/3.cgi";
    if (mode === "current") {
      url += "?mode=fetch_word_size";
    } else {
      url += "?mode=fetch_progress";
      url += "&duration=" + day;
    }
    return url;
  }

}


let executor = new Executor();
window.addEventListener("load", () => {
  executor.prepare();
});
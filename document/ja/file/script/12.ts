//


const DICTIONARY_URL = "conlang/database/1.cgi";

type DayType = {current: 0, difference: number};

export function prepare(): void {
  fetch("#whole-count", "current", 0);
  fetch("#week-count", "difference", 7);
  fetch("#month-count", "difference", 30);
}

export function fetch<M extends keyof DayType>(query: string, mode: M, day: DayType[M]): void {
  let request = new XMLHttpRequest();
  let url = DICTIONARY_URL + "?mode=fetch";
  if (mode === "current") {
    url += "&type=1";
  } else {
    url += "&type=3";
    url += "&agree=" + day;
  }
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

window.onload = prepare;
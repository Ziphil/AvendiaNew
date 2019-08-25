//


const DIGIT_SIZE = 3;
const RATING_WEIGHT = 0.9;
const CORRECTION_WEIGHT = 0.9;
const SCALING_CONSTANT = 100;
const MAX_CORRECTION = 90;
const MAX_CORRECTION_RATE = 0.8;

const OVERALL_MIN_RATING = 0;
const OVERALL_MAX_RATING = 300;

const OVERALL_MIN_DATE = new Date(1970, 0, 1);
const OVERALL_MAX_DATE = new Date(2099, 11, 31);

const CHART_WIDTH = 605;
const CHART_HEIGHT = 400;
const CHART_OFFSET_LEFT = 35;
const CHART_OFFSET_TOP = 50;
const CHART_MARGIN = 40;
const CHART_BORDER_RADIUS = 10;
const POPUP_DISTANCE = 100;

const MARKER_SIZE = 3;
const MARKER_BORDER_WIDTH = 1;
const LARGE_MARKER_SIZE = 6;

const CHART_LINE_WIDTH = 2;
const CHART_GAP_WIDTH = 2;

const PARTICLE_LIFE = 500;
const PARTICLE_MAX_RADIUS = 15;
const PARTICLE_LINE_WIDTH = 2;

const COLOR_SIZE = 8;
const COLOR_SPAN = 30;
const COLOR_NAMES = ["grey", "brown", "green", "cyan", "blue", "yellow", "orange", "red"];

const TWITTER_WIDTH = 560;
const TWITTER_HEIGHT = 320;
const TWITTER_MESSAGE = "My weblio vocabulary rating is now %r (%c)!"
const TWITTER_HASHTAG = "WeblioRating";

const INTERVAL = 50;
const COOKIE_AGE = 10000;

const INTERFACE_URL = "../../file/interface/2.cgi";

type HistoryMode = 0 | 1;
type Coordinates = {x: number, y: number};


export interface Parameter {
  
  input: string | undefined;
  number: string | null;
  mode: number;

}


export class HistoryEntry {

  date: Date;
  score: number;
  rating: number;
  x: number;
  y: number;
  firstIndex: number;

  constructor(date: Date, score: number, firstIndex: number) {
    this.date = date;
    this.score = score;
    this.rating = 0;
    this.x = 0;
    this.y = 0;
    this.firstIndex = firstIndex;
  }

}


export class History {

  entries: HistoryEntry[];
  minRating: number;
  maxRating: number;
  minDate: Date;
  maxDate: Date;
  mode: HistoryMode;

  constructor() {
    this.entries = [];
    this.minRating = OVERALL_MAX_RATING;
    this.maxRating = OVERALL_MAX_RATING;
    this.minDate = OVERALL_MIN_DATE;
    this.maxDate = OVERALL_MAX_DATE;
    this.mode = 0;
  }

  update(text: string, mode: HistoryMode): void {
    let splitText = text.split(/\r\n|\r|\n/);
    this.entries = [];
    this.mode = mode;
    for (let i = 0 ; i < splitText.length ; i ++) {
      let line = splitText[i];
      let match = line.match(/^\s*(\d+)\/(\d+)\/(\d+)\s*,\s*(\d+(?:\.\d+)?)\s*$/m);
      if (match != null) {
        let year = parseInt(match[1]);
        let month = parseInt(match[2]);
        let day = parseInt(match[3]);
        let score = parseFloat(match[4]);
        let date = new Date(year, month - 1, day);
        let trimedScore = Math.min(Math.max(score, OVERALL_MIN_RATING), OVERALL_MAX_RATING);
        let entry = new HistoryEntry(date, trimedScore, i);
        this.entries.push(entry);
      }
    }
    this.entries.sort((first, second) => {
      if (first.date < second.date) {
        return -1;
      } else if (first.date > second.date) {
        return 1;
      } else {
        return first.firstIndex - second.firstIndex;
      }
    });
    this.calculateRating();
    this.calculateMinMaxRating();
    this.calculateMinMaxDate();
    this.calculateCoordinates();
  }

  calculateRating(): void {
    let entries = this.entries;
    for (let i = 0 ; i < entries.length ; i ++) {
      let num = 0;
      let denom = 0;
      for (let j = i ; j >= 0 ; j --) {
        num += History.scaling(entries[j].score) * (RATING_WEIGHT ** (i - j));
        denom += RATING_WEIGHT ** (i - j);
      }
      let rawRating = History.inverseScaling(num / denom);
      let rating = rawRating - History.correction(i, rawRating);
      rating = Math.min(Math.max(rating, OVERALL_MIN_RATING), OVERALL_MAX_RATING);
      entries[i].rating = rating;
    }
  }

  calculateMinMaxRating(): void {
    let minRating = OVERALL_MAX_RATING;
    let maxRating = OVERALL_MIN_RATING;
    for (let entry of this.entries) {
      if (entry.rating > maxRating) {
        maxRating = entry.rating;
      }
      if (entry.rating < minRating) {
        minRating = entry.rating;
      }
    }
    this.minRating = Math.max(minRating - 10, OVERALL_MIN_RATING);
    this.maxRating = Math.min(maxRating + 10, OVERALL_MAX_RATING);
  }

  calculateMinMaxDate(): void {
    let minDate = OVERALL_MIN_DATE;
    let maxDate = OVERALL_MAX_DATE;
    for (let entry of this.entries) {
      if (entry.date > maxDate) {
        maxDate = entry.date;
      }
      if (entry.date < minDate) {
        minDate = entry.date;
      }
    }
    this.minDate = minDate;
    this.maxDate = maxDate;
  }

  calculateCoordinates(): void {
    let entries = this.entries;
    for (let i = 0 ; i < entries.length ; i ++) {
      let rating = entries[i].rating;
      entries[i].x = this.x(i);
      entries[i].y = this.y(rating);
    }
  }

  x(index: number): number {
    let entries = this.entries;
    if (this.mode == 0) {
      let length = entries.length;
      if (length > 1) {
        return (CHART_WIDTH - CHART_MARGIN * 2) / (length - 1) * index + CHART_MARGIN + CHART_OFFSET_LEFT;
      } else {
        return CHART_WIDTH / 2 + CHART_OFFSET_LEFT;
      }
    } else {
      let length = Math.floor((this.maxDate.getTime() - this.minDate.getTime()) / (1000 * 60 * 60 * 24));
      let elapsedDay = Math.floor((entries[index].date.getTime() - this.minDate.getTime()) / (1000 * 60 * 60 * 24));
      if (length > 0) {
        return (CHART_WIDTH - CHART_MARGIN * 2) / length * elapsedDay + CHART_MARGIN + CHART_OFFSET_LEFT;
      } else {
        return CHART_WIDTH / 2 + CHART_OFFSET_LEFT;
      }
    }
  }

  y(value: number): number {
    return CHART_HEIGHT - (value - this.minRating) / (this.maxRating - this.minRating) * CHART_HEIGHT + CHART_OFFSET_TOP;
  }

  static scaling(value: number): number {
    if (SCALING_CONSTANT > 0) {
      return 2 ** (value / SCALING_CONSTANT);
    } else {
      return value;
    }
  }

  static inverseScaling(value: number): number {
    if (SCALING_CONSTANT > 0) {
      return Math.log(value) / Math.log(2) * SCALING_CONSTANT;
    } else {
      return value;
    }
  }

  static correction(round: number, value: number): number {
    let num = 0;
    let denom = 0;
    for (let i = 0 ; i < round + 1 ; i ++) {
      num += CORRECTION_WEIGHT ** (i * 2);
      denom += CORRECTION_WEIGHT ** i;
    }
    let current = Math.sqrt(num) / denom;
    let max = (1 - CORRECTION_WEIGHT) / Math.sqrt(1 - CORRECTION_WEIGHT ** 2);
    let correction = (current - max) / (1 - max) * Math.min(value * MAX_CORRECTION_RATE, MAX_CORRECTION);
    return correction;
  }

  static colorIndex(rating: number): number {
    return Math.min(Math.floor(rating / COLOR_SPAN), COLOR_SIZE - 1);
  }

}


export class ChartRenderer {

  context: CanvasRenderingContext2D;
  history: History;
  mouse: Coordinates;
  nearestIndex: number;
  previousIndex: number | null;
  particles: {index: number, createdTime: number}[];
  timerSet: boolean;

  constructor(context: CanvasRenderingContext2D) {
    this.context = context;
    this.history = new History();
    this.mouse = {x: 0, y: 0};
    this.nearestIndex = 0;
    this.previousIndex = null;
    this.particles = [];
    this.timerSet = false;
    this.context.canvas.addEventListener("mousemove", (event) => {
      let target = <HTMLElement>event.target
      let rect = target.getBoundingClientRect();
      this.mouse.x = event.clientX - rect.left;
      this.mouse.y = event.clientY - rect.top;
    });
  }

  update(history: History): void {
    this.history = history;
    this.nearestIndex = history.entries.length - 1;
    this.previousIndex = null;
    this.particles = [];
  }

  render(): void {
    if (!this.timerSet) {
      setInterval(this.render.bind(this), INTERVAL);
      this.timerSet = true;
    }
    this.clearCanvas();
    if (this.history.entries.length > 0) {
      this.context.save();
      this.makeClipPath();
      this.context.clip();
      this.renderBackground();
      this.calculateNearestIndex();
      this.renderLine();
      this.renderParticles();
      this.renderMarker();
      this.context.restore();
      this.renderAxis();
      this.renderRating();
    }
  }

  clearCanvas(): void {
    let context = this.context;
    context.clearRect(0, 0, context.canvas.width, context.canvas.height);
  }

  makeClipPath(): void {
    let context = this.context;
    context.beginPath();
    context.arc(CHART_OFFSET_LEFT + CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, -Math.PI, -Math.PI / 2, false);
    context.arc(CHART_OFFSET_LEFT + CHART_WIDTH - CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, -Math.PI / 2, 0, false);
    context.arc(CHART_OFFSET_LEFT + CHART_WIDTH - CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_HEIGHT - CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, 0, Math.PI / 2, false);
    context.arc(CHART_OFFSET_LEFT + CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_HEIGHT - CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, Math.PI / 2, Math.PI, false);
    context.closePath();
  }

  renderBackground(): void {
    let context = this.context;
    let history = this.history;
    for (let i = COLOR_SIZE - 1 ; i >= 0 ; i --) {
      let y = (i < COLOR_SIZE - 1) ? history.y(COLOR_SPAN * (i + 1)) : CHART_OFFSET_TOP;
      let height = (i < COLOR_SIZE - 1) ? history.y(COLOR_SPAN * i) - history.y(COLOR_SPAN * (i + 1)) + 20 : CHART_HEIGHT;
      let gapWidth = CHART_GAP_WIDTH;
      context.fillStyle = document.querySelector<HTMLElement>(".background-" + i)!.style.color!;
      context.beginPath();
      context.rect(CHART_OFFSET_LEFT, Math.floor(y), CHART_WIDTH, height);
      context.fill();
      context.clearRect(CHART_OFFSET_LEFT, Math.floor(y - gapWidth / 2), CHART_WIDTH, gapWidth);
    }
  }

  calculateNearestIndex(): void {
    let entries = this.history.entries;
    let currentDate = new Date();
    let minDistance = null;
    let nearestIndex = null;
    for (let i = 0 ; i < entries.length ; i ++) {
      let distance = (entries[i].x - this.mouse.x) ** 2 + (entries[i].y - this.mouse.y) ** 2;
      if (distance < POPUP_DISTANCE && (minDistance == null || distance < minDistance)) {
        minDistance = distance;
        nearestIndex = i;
      }
    }
    if (nearestIndex != null) {
      if (nearestIndex != this.nearestIndex && nearestIndex != this.previousIndex) {
        this.particles.push({index: nearestIndex, createdTime: currentDate.getTime()});
      }
      this.nearestIndex = nearestIndex;
    }
    this.previousIndex = nearestIndex;
  }

  renderLine(): void {
    let context = this.context;
    let entries = this.history.entries;
    for (let i = 1 ; i < entries.length ; i ++) {
      context.strokeStyle = document.querySelector<HTMLElement>(".chart-line")!.style.color!;
      context.lineWidth = CHART_LINE_WIDTH;
      context.beginPath();
      context.moveTo(entries[i - 1].x, entries[i - 1].y);
      context.lineTo(entries[i].x, entries[i].y);
      context.stroke();
    }
  }

  renderParticles(): void {
    let context = this.context;
    let entries = this.history.entries;
    let currentDate = new Date();
    for (let particle of this.particles) {
      let entry = entries[particle.index];
      let elapsedTime = currentDate.getTime() - particle.createdTime;
      if (elapsedTime < PARTICLE_LIFE) {
        let radius = elapsedTime / PARTICLE_LIFE * (PARTICLE_MAX_RADIUS - LARGE_MARKER_SIZE) + LARGE_MARKER_SIZE;
        let alpha = 1 - elapsedTime / PARTICLE_LIFE;
        context.strokeStyle = document.querySelector<HTMLElement>(".marker-" + History.colorIndex(entry.rating))!.style.color!;
        context.lineWidth = PARTICLE_LINE_WIDTH;
        context.globalAlpha = alpha;
        context.beginPath();
        context.arc(entry.x, entry.y, radius, 0, Math.PI * 2, false);
        context.stroke();
      }
    }
    this.particles = this.particles.filter((particle) => {
      return currentDate.getTime() - particle.createdTime < PARTICLE_LIFE;
    });
    context.globalAlpha = 1;
  }

  renderMarker(): void {
    let context = this.context;
    let entries = this.history.entries;
    for (let j = 0 ; j < entries.length ; j ++) {
      let i = (j < this.nearestIndex) ? j : (j < entries.length - 1) ? j + 1 : this.nearestIndex; 
      let rating = entries[i].rating;
      let radius = (i == this.nearestIndex) ? LARGE_MARKER_SIZE : MARKER_SIZE;
      let borderWidth = MARKER_BORDER_WIDTH;
      context.fillStyle = document.querySelector<HTMLElement>(".chart-line")!.style.color!;
      context.beginPath();
      context.arc(entries[i].x, entries[i].y, radius + 1, 0, Math.PI * 2, false);
      context.fill();
      context.fillStyle = document.querySelector<HTMLElement>(".marker-" + History.colorIndex(rating))!.style.color!;
      context.beginPath();
      context.arc(entries[i].x, entries[i].y, radius, 0, Math.PI * 2, false);
      context.fill();
    }
  }

  renderAxis(): void {
    let context = this.context;
    let history = this.history;
    for (let i = 0 ; i < COLOR_SIZE - 1 ; i ++) {
      let y = history.y(COLOR_SPAN * (i + 1));
      if (y < CHART_OFFSET_TOP + CHART_HEIGHT && y > CHART_OFFSET_TOP) {
        context.font = document.querySelector<HTMLElement>(".chart-axis")!.style.font!;
        context.textAlign = "right";
        context.textBaseline = "middle";
        context.fillStyle = "black";
        context.fillText((COLOR_SPAN * (i + 1)).toString(), CHART_OFFSET_LEFT - 8, y);
      }
    }
  }

  renderRating(): void {
    let context = this.context;
    let entries = this.history.entries;
    let index = this.nearestIndex;
    let rating = entries[index].rating;
    context.font = document.querySelector<HTMLElement>(".chart-rating")!.style.font!;
    context.textAlign = "right";
    context.textBaseline = "alphabetic";
    context.fillStyle = document.querySelector<HTMLElement>(".marker-" + History.colorIndex(rating))!.style.color!;
    context.fillText(rating.toFixed(DIGIT_SIZE), CHART_OFFSET_LEFT + CHART_WIDTH - 10, CHART_OFFSET_TOP - 10);
    context.font = document.querySelector<HTMLElement>(".chart-date")!.style.font!;
    context.textAlign = "left";
    context.textBaseline = "alphabetic";
    context.fillText(TagFactory.createDateString(entries[index].date), CHART_OFFSET_LEFT + 10, CHART_OFFSET_TOP - 10);
    if (index == entries.length - 1) {
      context.font = document.querySelector<HTMLElement>(".chart-message")!.style.font!;
      context.textAlign = "left";
      context.textBaseline = "alphabetic";
      context.fillText("Latest", CHART_OFFSET_LEFT + 10, CHART_OFFSET_TOP - 30);
    }
  }

}


export class TagFactory {

  history: History;

  constructor() {
    this.history = new History();
  }

  update(history: History): void {
    this.history = history;
  }

  create(): HTMLElement {
    let entries = this.history.entries;
    let table = document.createElement("table");
    for (let i = 0 ; i < entries.length ; i ++) {
      let tr = document.createElement("tr");
      let dateString = TagFactory.createDateString(entries[i].date);
      let scoreString = entries[i].score.toFixed(1);
      let previousRating = (i > 0) ? entries[i - 1].rating : 0;
      let rating = entries[i].rating;
      let differenceSign = (rating - previousRating >= 0) ? "+ " : "− ";
      let difference = Math.abs(rating - previousRating);
      let previousRatingString = (i > 0) ? previousRating.toFixed(DIGIT_SIZE) : "";
      let ratingString = rating.toFixed(DIGIT_SIZE);
      let differenceString = differenceSign + difference.toFixed(DIGIT_SIZE);
      tr.appendChild(TagFactory.createTd((i + 1).toString(), "number"));
      tr.appendChild(TagFactory.createTd(dateString, "date"));
      tr.appendChild(TagFactory.createTd(scoreString, "score"));
      tr.appendChild(TagFactory.createTd(previousRatingString, "previous-rating", previousRating));
      tr.appendChild(TagFactory.createTd("\uF003", "arrow"));
      tr.appendChild(TagFactory.createTd(ratingString, "rating", rating));
      tr.appendChild(TagFactory.createTd(differenceString, "difference"));
      table.insertBefore(tr, table.firstChild);
    }
    return table;
  }

  static createTd(text: string, clazz: string, rating?: number): HTMLElement {
    let td = document.createElement("td");
    let properClass = (rating == undefined) ? clazz : clazz + " marker-" + History.colorIndex(rating);
    td.setAttribute("class", properClass);
    td.textContent = text;
    return td;
  }

  static createDateString(date: Date): string {
    let string = "";
    string += ("000" + date.getFullYear()).slice(-4);
    string += "/";
    string += ("0" + (date.getMonth() + 1)).slice(-2);
    string += "/";
    string += ("0" + date.getDate()).slice(-2);
    return string;
  }

}


export class Executor {

  context: CanvasRenderingContext2D | null;
  history: History;
  renderer: ChartRenderer | null;
  factory: TagFactory;

  constructor() {
    this.context = null;
    this.history = new History();
    this.renderer = null;
    this.factory = new TagFactory();
  }

  getItem(keys: string[]): string | undefined {
    let value = undefined;
    for (let key of keys) {
      let candidate = localStorage.getItem(key);
      if (candidate != null && candidate != undefined) {
        value = candidate;
        break;
      }
    }
    return value;
  }

  setItem(key: string, value: string, option?: any): void {
    localStorage.setItem(key, value);
  }

  getParameters(): Parameter {
    let input = this.getItem(["randomizer_input", "input"]);
    let number = null;
    let modeString = this.getItem(["randomizer_mode", "mode"]);
    let mode = (modeString != null) ? parseInt(modeString) : null;
    let pairs = location.search.substring(1).split("&");
    for (let pair of pairs) {
      let match = <RegExpMatchArray | null>null;
      if ((match = pair.match(/input=(.+)/)) != null) {
        input = decodeURIComponent(match[1]);
      } else if ((match = pair.match(/number=(.+)/)) != null) {
        number = decodeURIComponent(match[1]);
      } else if ((match = pair.match(/mode=(.+)/)) != null) {
        mode = parseInt(decodeURIComponent(match[1]));
      }
    }
    if (mode == null || Number.isNaN(mode)) {
      mode = 0;
    }
    return {input: input, number: number, mode: mode};
  }

  prepareForms(): void {
    let parameters = this.getParameters();
    let go = () => {
      if (parameters.input != undefined) {
        document.querySelector<HTMLInputElement>("#input")!.value = parameters.input;
      }
      if (parameters.mode != null) {
        let modeElements = document.querySelectorAll<HTMLInputElement>("input[name=\"mode\"]");
        for (let element of modeElements) {
          if (element.value == parameters.mode.toString()) {
            element.checked = true;
          }
        }
      }
      for (let i = 0 ; i < COLOR_SIZE ; i ++) {
        let canvas = document.querySelector("#canvas")!;
        let markerDiv = document.createElement("div");
        let backgroundDiv = document.createElement("div");
        markerDiv.setAttribute("class", "marker-" + i);
        backgroundDiv.setAttribute("class", "background-" + i);
        canvas.append(markerDiv, backgroundDiv);
      }
      if (parameters.input != undefined) {
        this.execute(true);
      }
    };
    if (parameters.number != null) {
      document.querySelector<HTMLInputElement>("#input")!.value = "Loading";
      let request = new XMLHttpRequest();
      let url = INTERFACE_URL + "?mode=get&number=" + parameters.number;
      request.open("GET", url, true);
      request.send(null);
      request.addEventListener("readystatechange", (event) => {
        if (request.readyState == 4 && request.status == 200) {
          parameters.input = request.responseText;
          go();
        }
      });
    } else {
      go();
    }
  }

  prepare(): void {
    this.context = document.querySelector<HTMLCanvasElement>("#canvas")!.getContext("2d")!;
    this.history = new History();
    this.renderer = new ChartRenderer(this.context);
    this.factory = new TagFactory();
    this.prepareForms();
  }

  reset(): void {
    for (let element of document.querySelectorAll(".content .main .history")) {
      element.remove();
    }
  }

  start(): void {
    let chartDiv = document.querySelector(".content .main .chart")!;
    let historyDiv = document.createElement("div")!;
    let table = this.factory.create();
    historyDiv.setAttribute("class", "history");
    historyDiv.appendChild(table);
    chartDiv.after(historyDiv);
    this.renderer!.render();
  }

  execute(first: boolean): void {
    let input = document.querySelector<HTMLInputElement>("#input")!.value;
    let modeString = document.querySelector<HTMLInputElement>("input[name=\"mode\"]:checked")!.value;
    let mode = <HistoryMode>parseInt(modeString);
    this.history.update(input, mode);
    this.renderer!.update(this.history);
    this.factory.update(this.history);
    this.reset();
    this.start();
    if (!first) {
      this.setItem("randomizer_input", input, {path: "", expires: COOKIE_AGE});
      this.setItem("randomizer_mode", mode.toString(), {path: "", expires: COOKIE_AGE});
    }
  }

  tweet() {
    let entries = this.history.entries;
    if (entries != undefined && entries.length > 0) {
      let input = document.querySelector<HTMLInputElement>("#input")!.value;
      let rating = entries[entries.length - 1].rating;
      let ratingString = rating.toFixed(DIGIT_SIZE);
      let colorName = COLOR_NAMES[History.colorIndex(rating)];
      let numberRequest = new XMLHttpRequest();
      let numberUrl = INTERFACE_URL + "?mode=get_number";
      numberRequest.open("GET", numberUrl, true);
      numberRequest.send(null);
      numberRequest.addEventListener("readystatechange", (event) => {
        if (numberRequest.readyState == 4 && numberRequest.status == 200) {
          let number = numberRequest.responseText;
          let url = location.protocol + "//" + location.host + location.pathname;
          let option = "width=" + TWITTER_WIDTH + ",height=" + TWITTER_HEIGHT + ",menubar=no,toolbar=no,scrollbars=no";
          let href = "https://twitter.com/intent/tweet";
          url += "?number=" + encodeURIComponent(number);
          url += "&mode=" + this.history.mode;
          href += "?text=" + TWITTER_MESSAGE.replace(/%r/g, ratingString).replace(/%c/g, colorName);
          href += "&url=" + encodeURIComponent(url);
          href += "&hashtags=" + TWITTER_HASHTAG;
          let twitterRequest = new XMLHttpRequest();
          let twitterUrl = INTERFACE_URL
          let data = "mode=save&number=" + number + "&content=" + encodeURIComponent(input);
          twitterRequest.open("POST", twitterUrl);
          twitterRequest.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
          twitterRequest.send(data);
          window.open(href, "_blank", option);
        }
      });
    }
  }

}


let executor = new Executor();
window.addEventListener("load", () => {
  executor.prepare();
});
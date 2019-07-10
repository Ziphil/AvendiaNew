//


const DIGIT_SIZE = 3;
const RATING_WEIGHT = 0.9;
const CORRECTION_WEIGHT = 0.9;
const SCALING_CONSTANT = 100;
const MAX_CORRECTION = 90;
const MAX_CORRECTION_RATE = 0.8;

const OVERALL_MIN_RATING = 0;
const OVERALL_MAX_RATING = 300;

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


class History {

  update(text, mode) {
    let splitText = text.split(/\r\n|\r|\n/);
    this.entries = [];
    this.mode = mode;
    for (let i = 0 ; i < splitText.length ; i ++) {
      let line = splitText[i];
      let match;
      if ((match = line.match(/^\s*(\d+)\/(\d+)\/(\d+)\s*,\s*(\d+(?:\.\d+)?)\s*$/m)) != null) {
        let year = parseInt(match[1]);
        let month = parseInt(match[2]);
        let day = parseInt(match[3]);
        let score = parseFloat(match[4]);
        let date = new Date(year, month - 1, day);
        score = Math.min(Math.max(score, OVERALL_MIN_RATING), OVERALL_MAX_RATING);
        this.entries.push({date: date, score: score, firstIndex: i});
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

  calculateRating() {
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

  calculateMinMaxRating() {
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

  calculateMinMaxDate() {
    let minDate = new Date(2099, 11, 31);
    let maxDate = new Date(1970, 0, 1);
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

  calculateCoordinates() {
    let entries = this.entries;
    for (let i = 0 ; i < entries.length ; i ++) {
      let rating = entries[i].rating;
      entries[i].x = this.x(i);
      entries[i].y = this.y(rating);
    }
  }

  x(index) {
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

  y(value) {
    return CHART_HEIGHT - (value - this.minRating) / (this.maxRating - this.minRating) * CHART_HEIGHT + CHART_OFFSET_TOP;
  }

  static scaling(value) {
    if (SCALING_CONSTANT > 0) {
      return 2 ** (value / SCALING_CONSTANT);
    } else {
      return value;
    }
  }

  static inverseScaling(value) {
    if (SCALING_CONSTANT > 0) {
      return Math.log(value) / Math.log(2) * SCALING_CONSTANT;
    } else {
      return value;
    }
  }

  static correction(round, value) {
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

  static colorIndex(rating) {
    return Math.min(Math.floor(rating / COLOR_SPAN), COLOR_SIZE - 1);
  }

}


class ChartRenderer {

  constructor(context) {
    this.context = context;
    this.mouse = {x: 0, y: 0};
    this.timerSet = false;
    this.context.canvas.addEventListener("mousemove", (event) => {
      var rect = event.target.getBoundingClientRect();
      this.mouse.x = event.clientX - rect.left;
      this.mouse.y = event.clientY - rect.top;
    });
  }

  update(history) {
    this.history = history;
    this.nearestIndex = history.entries.length - 1;
    this.previousIndex = null;
    this.particles = [];
  }

  render() {
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

  clearCanvas() {
    let context = this.context;
    context.clearRect(0, 0, context.canvas.width, context.canvas.height);
  }

  makeClipPath() {
    let context = this.context;
    context.beginPath();
    context.arc(CHART_OFFSET_LEFT + CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, -Math.PI, -Math.PI / 2, false);
    context.arc(CHART_OFFSET_LEFT + CHART_WIDTH - CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, -Math.PI / 2, 0, false);
    context.arc(CHART_OFFSET_LEFT + CHART_WIDTH - CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_HEIGHT - CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, 0, Math.PI / 2, false);
    context.arc(CHART_OFFSET_LEFT + CHART_BORDER_RADIUS, CHART_OFFSET_TOP + CHART_HEIGHT - CHART_BORDER_RADIUS, CHART_BORDER_RADIUS, Math.PI / 2, Math.PI, false);
    context.closePath();
  }

  renderBackground() {
    let context = this.context;
    let history = this.history;
    for (let i = COLOR_SIZE - 1 ; i >= 0 ; i --) {
      let y = (i < COLOR_SIZE - 1) ? history.y(COLOR_SPAN * (i + 1)) : CHART_OFFSET_TOP;
      let height = (i < COLOR_SIZE - 1) ? history.y(COLOR_SPAN * i) - history.y(COLOR_SPAN * (i + 1)) + 20 : CHART_HEIGHT;
      let gapWidth = CHART_GAP_WIDTH;
      context.fillStyle = $(".background-" + i).css("color");
      context.beginPath();
      context.rect(CHART_OFFSET_LEFT, Math.floor(y), CHART_WIDTH, height);
      context.fill();
      context.clearRect(CHART_OFFSET_LEFT, Math.floor(y - gapWidth / 2), CHART_WIDTH, gapWidth);
    }
  }

  calculateNearestIndex() {
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

  renderLine() {
    let context = this.context;
    let entries = this.history.entries;
    for (let i = 1 ; i < entries.length ; i ++) {
      context.strokeStyle = $(".chart-line").css("color");
      context.lineWidth = CHART_LINE_WIDTH;
      context.beginPath();
      context.moveTo(entries[i - 1].x, entries[i - 1].y);
      context.lineTo(entries[i].x, entries[i].y);
      context.stroke();
    }
  }

  renderParticles() {
    let context = this.context;
    let entries = this.history.entries;
    let currentDate = new Date();
    for (let particle of this.particles) {
      let entry = entries[particle.index];
      let elapsedTime = currentDate.getTime() - particle.createdTime;
      if (elapsedTime < PARTICLE_LIFE) {
        let radius = elapsedTime / PARTICLE_LIFE * (PARTICLE_MAX_RADIUS - LARGE_MARKER_SIZE) + LARGE_MARKER_SIZE;
        let alpha = 1 - elapsedTime / PARTICLE_LIFE;
        context.strokeStyle = $(".marker-" + History.colorIndex(entry.rating)).css("color");
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

  renderMarker() {
    let context = this.context;
    let entries = this.history.entries;
    for (let j = 0 ; j < entries.length ; j ++) {
      let i = (j < this.nearestIndex) ? j : (j < entries.length - 1) ? j + 1 : this.nearestIndex; 
      let rating = entries[i].rating;
      let radius = (i == this.nearestIndex) ? LARGE_MARKER_SIZE : MARKER_SIZE;
      let borderWidth = MARKER_BORDER_WIDTH;
      context.fillStyle = $(".chart-line").css("color");
      context.beginPath();
      context.arc(entries[i].x, entries[i].y, radius + 1, 0, Math.PI * 2, false);
      context.fill();
      context.fillStyle = $(".marker-" + History.colorIndex(rating)).css("color");
      context.beginPath();
      context.arc(entries[i].x, entries[i].y, radius, 0, Math.PI * 2, false);
      context.fill();
    }
  }

  renderAxis() {
    let context = this.context;
    let history = this.history;
    for (let i = 0 ; i < COLOR_SIZE - 1 ; i ++) {
      let y = history.y(COLOR_SPAN * (i + 1));
      if (y < CHART_OFFSET_TOP + CHART_HEIGHT && y > CHART_OFFSET_TOP) {
        context.font = $(".chart-axis").css("font");
        context.textAlign = "right";
        context.textBaseline = "middle";
        context.fillStyle = "black";
        context.fillText(COLOR_SPAN * (i + 1), CHART_OFFSET_LEFT - 8, y);
      }
    }
  }

  renderRating() {
    let context = this.context;
    let entries = this.history.entries;
    let index = this.nearestIndex;
    let rating = entries[index].rating;
    context.font = $(".chart-rating").css("font");
    context.textAlign = "right";
    context.textBaseline = "alphabetic";
    context.fillStyle = $(".marker-" + History.colorIndex(rating)).css("color");
    context.fillText(rating.toFixed(DIGIT_SIZE), CHART_OFFSET_LEFT + CHART_WIDTH - 10, CHART_OFFSET_TOP - 10);
    context.font = $(".chart-date").css("font");
    context.textAlign = "left";
    context.textBaseline = "alphabetic";
    context.fillText(TagFactory.createDateString(entries[index].date), CHART_OFFSET_LEFT + 10, CHART_OFFSET_TOP - 10);
    if (index == entries.length - 1) {
      context.font = $(".chart-message").css("font");
      context.textAlign = "left";
      context.textBaseline = "alphabetic";
      context.fillText("Latest", CHART_OFFSET_LEFT + 10, CHART_OFFSET_TOP - 30);
    }
  }

}


class TagFactory {

  update(history) {
    this.history = history;
  }

  create() {
    let entries = this.history.entries;
    let table = $("<table>");
    for (let i = 0 ; i < entries.length ; i ++) {
      let tr = $("<tr>");
      let dateString = TagFactory.createDateString(entries[i].date);
      let scoreString = entries[i].score.toFixed(1);
      let previousRating = (i > 0) ? entries[i - 1].rating : 0;
      let rating = entries[i].rating;
      let differenceSign = (rating - previousRating >= 0) ? "+ " : "− ";
      let difference = Math.abs(rating - previousRating);
      let previousRatingString = (i > 0) ? previousRating.toFixed(DIGIT_SIZE) : "";
      let ratingString = rating.toFixed(DIGIT_SIZE);
      let differenceString = differenceSign + difference.toFixed(DIGIT_SIZE);
      tr.append(TagFactory.createTd(i + 1, "number"));
      tr.append(TagFactory.createTd(dateString, "date"));
      tr.append(TagFactory.createTd(scoreString, "score"));
      tr.append(TagFactory.createTd(previousRatingString, "previous-rating", previousRating));
      tr.append(TagFactory.createTd("\uF003", "arrow"));
      tr.append(TagFactory.createTd(ratingString, "rating", rating));
      tr.append(TagFactory.createTd(differenceString, "difference"));
      table.append(tr);
    }
    return table;
  }

  static createTd(text, clazz, rating) {
    let td = $("<td>");
    let properClass = (rating == undefined) ? clazz : clazz + " marker-" + History.colorIndex(rating);
    td = td.attr("class", properClass);
    td = td.text(text);
    return td;
  }

  static createDateString(date) {
    let string = "";
    string += ("000" + date.getFullYear()).slice(-4);
    string += "/";
    string += ("0" + (date.getMonth() + 1)).slice(-2);
    string += "/";
    string += ("0" + date.getDate()).slice(-2);
    return string;
  }

}


class Executor {

  getItem(keys) {
    let value = undefined;
    for (let key of keys) {
      let candidate = localStorage.getItem(key);
      if (candidate != null && candidate != undefined) {
        value = candidate;
        break;
      }
    }
    if (value == undefined) {
      for (let key of keys) {
        let candidate = Cookies.get(key);
        if (candidate != null && candidate != undefined) {
          value = candidate;
          break;
        }
      }
    }
    return value;
  }

  setItem(key, value, option) {
    localStorage.setItem(key, value);
  }

  getParameters() {
    let input = this.getItem(["randomizer_input", "input"]);
    let number = null;
    let mode = parseInt(this.getItem(["randomizer_mode", "mode"]));
    let pairs = location.search.substring(1).split("&");
    for (let pair of pairs) {
      let match;
      if ((match = pair.match(/input=(.+)/)) != null) {
        input = decodeURIComponent(match[1]);
      } else if ((match = pair.match(/number=(.+)/)) != null) {
        number = decodeURIComponent(match[1]);
      } else if ((match = pair.match(/mode=(.+)/)) != null) {
        mode = parseInt(decodeURIComponent(match[1]));
      }
    }
    if (Number.isNaN(mode)) {
      mode = 0;
    }
    return {input: input, number: number, mode: mode};
  }

  prepareForms() {
    let parameters = this.getParameters();
    let go = () => {
      if (parameters.input != undefined) {
        $("#input").val(parameters.input);
      }
      $("input[name=\"mode\"]").val([parameters.mode.toString()]);
      for (let i = 0 ; i < COLOR_SIZE ; i ++) {
        $("#canvas").append($("<div>").attr("class", "marker-" + i));
        $("#canvas").append($("<div>").attr("class", "background-" + i));
      }
      if (parameters.input != undefined) {
        this.execute(true);
      }
    };
    if (parameters.number != null) {
      $("#input").val("Loading");
      $.get(INTERFACE_URL, {mode: "get", number: parameters.number}, (input) => {
        parameters.input = input;
        go();
      });
    } else {
      go();
    }
  }

  prepare() {
    this.context = $("#canvas")[0].getContext("2d");
    this.history = new History();
    this.renderer = new ChartRenderer(this.context);
    this.factory = new TagFactory();
    this.prepareForms();
  }

  reset() {
    $(".content .main .history").remove();
  }

  start() {
    let chartDiv = $(".content .main .chart");
    let historyDiv = $("<div>").attr("class", "history");
    let table = this.factory.create();
    historyDiv.append(table);
    chartDiv.after(historyDiv);
    this.renderer.render();
  }

  execute(first) {
    let input = $("#input").val();
    let mode = parseInt($("input[name=\"mode\"]:checked").val());
    this.history.update(input, mode);
    this.renderer.update(this.history);
    this.factory.update(this.history);
    this.reset();
    this.start();
    if (!first) {
      this.setItem("randomizer_input", input, {path: "", expires: COOKIE_AGE});
      this.setItem("randomizer_mode", mode, {path: "", expires: COOKIE_AGE});
    }
  }

  tweet() {
    let entries = this.history.entries;
    if (entries != undefined && entries.length > 0) {
      let input = $("#input").val();
      let rating = entries[entries.length - 1].rating;
      let ratingString = rating.toFixed(DIGIT_SIZE);
      let colorName = COLOR_NAMES[History.colorIndex(rating)];
      $.get(INTERFACE_URL, {mode: "get_number"}, (number) => {
        let url = location.protocol + "//" + location.host + location.pathname;
        let option = "width=" + TWITTER_WIDTH + ",height=" + TWITTER_HEIGHT + ",menubar=no,toolbar=no,scrollbars=no";
        let href = "https://twitter.com/intent/tweet";
        url += "?number=" + encodeURIComponent(number);
        url += "&mode=" + this.history.mode;
        href += "?text=" + TWITTER_MESSAGE.replace(/%r/g, ratingString).replace(/%c/g, colorName);
        href += "&url=" + encodeURIComponent(url);
        href += "&hashtags=" + TWITTER_HASHTAG;
        $.post(INTERFACE_URL, {mode: "save", content: input, number: number});
        window.open(href, "_blank", option);
      });
    }
  }

}


let executor = new Executor();
$(() => {
  executor.prepare();
});
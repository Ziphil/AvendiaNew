//


function setup() {
  let today = new Date();
  let year = today.getFullYear();
  let month = today.getMonth() + 1;
  let day = today.getDate();
  $("[name=\"gregorian-year\"]").val(year);
  $("[name=\"gregorian-month\"]").val(month);
  $("[name=\"gregorian-day\"]").val(day);
  convertGregorian();
  $("[name=\"convert-old-hairia\"]").on("click", convertOldHairia);
  $("[name=\"convert-new-hairia\"]").on("click", convertNewHairia);
  $("[name=\"convert-gregorian\"]").on("click", convertGregorian);
  $("[name=\"convert-hairia\"]").on("click", convertHairia);
  $("[name^=\"old-hairia\"]").on("keydown", (event) => {
    if (event.which == 13) {
      convertOldHairia();
      return false;
    }
  });
  $("[name^=\"new-hairia\"]").on("keydown", (event) => {
    if (event.which == 13) {
      convertNewHairia();
      return false;
    }
  });
  $("[name^=\"gregorian\"]").on("keydown", (event) => {
    if (event.which == 13) {
      convertGregorian();
      return false;
    }
  });
  $("[name=\"hairia\"]").on("keydown", (event) => {
    if (event.which == 13) {
      convertHairia();
      return false;
    } else if (event.which == 38) {
      $("[name=\"hairia\"]").val(parseInt($("[name=\"hairia\"]").val(), 10) + 1);
      convertHairia();
      return false;
    } else if (event.which == 40) {
      $("[name=\"hairia\"]").val(parseInt($("[name=\"hairia\"]").val(), 10) - 1);
      convertHairia();
      return false;
    }
  });
}

function convertOldHairia() {
  let year = parseInt($("[name=\"old-hairia-year\"]").val(), 10);
  let month = parseInt($("[name=\"old-hairia-month\"]").val(), 10);
  let day = parseInt($("[name=\"old-hairia-day\"]").val(), 10);
  let hairia = hairiaOfOldHairia(year, month, day);
  let newHairia = toNewHairia(hairia);
  let gregorian = toGregorian(hairia);
  set([year, month, day], newHairia, gregorian, hairia);
}

function convertNewHairia() {
  let year = parseInt($("[name=\"new-hairia-year\"]").val(), 10);
  let month = parseInt($("[name=\"new-hairia-month\"]").val(), 10);
  let day = parseInt($("[name=\"new-hairia-day\"]").val(), 10);
  let hairia = hairiaOfNewHairia(year, month, day);
  let oldHairia = toOldHairia(hairia);
  let gregorian = toGregorian(hairia);
  set(oldHairia, [year, month, day], gregorian, hairia);
}

function convertGregorian() {
  let year = parseInt($("[name=\"gregorian-year\"]").val(), 10);
  let month = parseInt($("[name=\"gregorian-month\"]").val(), 10);
  let day = parseInt($("[name=\"gregorian-day\"]").val(), 10);
  let hairia = hairiaOfGregorian(year, month, day);
  let oldHairia = toOldHairia(hairia);
  let newHairia = toNewHairia(hairia);
  set(oldHairia, newHairia, [year, month, day], hairia);
}

function convertHairia() {
  let hairia = parseInt($("[name=\"hairia\"]").val(), 10);
  let oldHairia = toOldHairia(hairia);
  let newHairia = toNewHairia(hairia);
  let gregorian = toGregorian(hairia);
  set(oldHairia, newHairia, gregorian, hairia);
}

function set(oldHairia, newHairia, gregorian, hairia) {
  $("[name=\"old-hairia-year\"]").val(oldHairia[0]);
  $("[name=\"old-hairia-month\"]").val(oldHairia[1]);
  $("[name=\"old-hairia-day\"]").val(oldHairia[2]);
  $("[name=\"new-hairia-year\"]").val(newHairia[0]);
  $("[name=\"new-hairia-month\"]").val(newHairia[1]);
  $("[name=\"new-hairia-day\"]").val(newHairia[2]);
  $("[name=\"gregorian-year\"]").val(gregorian[0]);
  $("[name=\"gregorian-month\"]").val(gregorian[1]);
  $("[name=\"gregorian-day\"]").val(gregorian[2]);
  $("[name=\"hairia\"]").val(hairia);
}

function toOldHairia(hairia) {
  let time = (hairia - 1) * 120000 + 1500 * 36000000;
  let nextYear = div(time, 36000000) + 1;
  let nextMonth = div(mod(time, 36000000), 3000000) + 1;
  let nextDay = div(mod(mod(time, 36000000), 3000000), 120000) + 1;
  return [nextYear, nextMonth, nextDay];
}

function toNewHairia(hairia) {
  let days = hairia + 547862;
  let year = div(4 * days + 3 + 4 * div(3 * (div(4 * (days + 1), 146097) + 1), 4), 1461);
  let remainder = days - (365 * year + div(year, 4) - div(year, 100) + div(year, 400))
  let nextYear = year + 1;
  let nextMonth = div(remainder, 33) + 1;
  let nextDay = mod(remainder, 33) + 1;
  return [nextYear, nextMonth, nextDay];
}

function toGregorian(hairia) {
  let julian = hairia + 734829;
  let year = 4 * julian + 3 + 4 * div(3 * (div(4 * (julian + 1), 146097) + 1), 4);
  let month = 5 * div(mod(year, 1461), 4) + 2;
  let temporaryYear = div(year, 1461);
  let temporaryMonth = div(month, 153);
  let temporaryDay = div(mod(month, 153), 5);
  let nextMonth = mod(temporaryMonth + 2, 12) + 1;
  let nextYear = temporaryYear - div(nextMonth - 3, 12);
  let nextDay = temporaryDay + 1;
  return [nextYear, nextMonth, nextDay];
}

function hairiaOfOldHairia(year, month, day) {
  return (year - 1501) * 300 + (month - 1) * 25 + day;
}

function hairiaOfNewHairia(year, month, day) {
  return 365 * (year - 1) + div(year - 1, 4) - div(year - 1, 100) + div(year - 1, 400) + (month - 1) * 33 + day - 547863;
}

function hairiaOfGregorian(year, month, day) {
  let temporaryYear = year + div(month - 3, 12);
  let temporaryMonth = mod(month - 3, 12);
  let temporaryDay = day - 1;
  return temporaryDay + div(153 * temporaryMonth + 2, 5) + 365 * temporaryYear + div(temporaryYear, 4) - div(temporaryYear, 100) + div(temporaryYear, 400) - 734829;
}

function div(a, b) {
  if (a >= 0) {
    return Math.floor(a / b);
  } else {
    return - Math.floor((b - a - 1) / b);
  }
}

function mod(a, b) {
  return a - div(a, b) * b;
}

$(setup);
//


type Hairia = number;


export class FloorMath {

  static div(a: number, b: number): number {
    if (a >= 0) {
      return Math.floor(a / b);
    } else {
      return - Math.floor((b - a - 1) / b);
    }
  }
  
  static mod(a: number, b: number): number {
    return a - FloorMath.div(a, b) * b;
  }

}


export class AbstractDate {

  year: number;
  month: number;
  day: number;

  constructor(year: number, month: number, day: number) {
    this.year = year;
    this.month = month;
    this.day = day;
  }

}


export abstract class Calendar {

  name: string;

  constructor(name: string = "") {
    this.name = name;
  }

  abstract fromHairia(hairia: Hairia): AbstractDate;

  abstract toHairia(date: AbstractDate): Hairia;

}


export class OldHairian extends Calendar {

  fromHairia(hairia: Hairia): AbstractDate {
    let time = (hairia - 1) * 120000 + 1500 * 36000000;
    let year = FloorMath.div(time, 36000000) + 1;
    let month = FloorMath.div(FloorMath.mod(time, 36000000), 3000000) + 1;
    let day = FloorMath.div(FloorMath.mod(FloorMath.mod(time, 36000000), 3000000), 120000) + 1;
    return new AbstractDate(year, month, day);
  }

  toHairia(date: AbstractDate): Hairia {
    let year = date.year;
    let month = date.month;
    let day = date.day;
    let hairia = (year - 1501) * 300 + (month - 1) * 25 + day;
    return hairia;
  }

}


export class NewHairian extends Calendar {

  fromHairia(hairia: Hairia): AbstractDate {
    let count = hairia + 547862;
    let rawYear = FloorMath.div(4 * count + 3 + 4 * FloorMath.div(3 * (FloorMath.div(4 * (count + 1), 146097) + 1), 4), 1461);
    let remainder = count - (365 * rawYear + FloorMath.div(rawYear, 4) - FloorMath.div(rawYear, 100) + FloorMath.div(rawYear, 400))
    let year = rawYear + 1;
    let month = FloorMath.div(remainder, 33) + 1;
    let day = FloorMath.mod(remainder, 33) + 1;
    return new AbstractDate(year, month, day);
  }

  toHairia(date: AbstractDate): Hairia {
    let year = date.year;
    let month = date.month;
    let day = date.day;
    let hairia = 365 * (year - 1) + FloorMath.div(year - 1, 4) - FloorMath.div(year - 1, 100) + FloorMath.div(year - 1, 400) + (month - 1) * 33 + day - 547863;
    return hairia;
  }

}


export class Gregorian extends Calendar {

  fromHairia(hairia: Hairia): AbstractDate {
    let julian = hairia + 734829;
    let rawYear = 4 * julian + 3 + 4 * FloorMath.div(3 * (FloorMath.div(4 * (julian + 1), 146097) + 1), 4);
    let rawMonth = 5 * FloorMath.div(FloorMath.mod(rawYear, 1461), 4) + 2;
    let tempYear = FloorMath.div(rawYear, 1461);
    let tempMonth = FloorMath.div(rawMonth, 153);
    let tempDay = FloorMath.div(FloorMath.mod(rawMonth, 153), 5);
    let month = FloorMath.mod(tempMonth + 2, 12) + 1;
    let year = tempYear - FloorMath.div(month - 3, 12);
    let day = tempDay + 1;
    return new AbstractDate(year, month, day);
  }

  fromDate(date: Date): AbstractDate {
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    let day = date.getDate();
    return new AbstractDate(year, month, day);
  }

  toHairia(date: AbstractDate): Hairia {
    let year = date.year;
    let month = date.month;
    let day = date.day;
    let tempYear = year + FloorMath.div(month - 3, 12);
    let tempMonth = FloorMath.mod(month - 3, 12);
    let tempDay = day - 1;
    let addition = FloorMath.div(153 * tempMonth + 2, 5) + 365 * tempYear + FloorMath.div(tempYear, 4) - FloorMath.div(tempYear, 100) + FloorMath.div(tempYear, 400) - 734829;
    let hairia = tempDay + addition;
    return hairia;
  }

}


export class RawHairia extends Calendar {
  
  fromHairia(hairia: Hairia): AbstractDate {
    let year = 0;
    let month = 0;
    let day = hairia;
    return new AbstractDate(year, month, day);
  }
  
  toHairia(date: AbstractDate): Hairia {
    let hairia = date.day;
    return hairia;
  }
  
}


export class Executor {

  calendars: Calendar[];

  constructor() {
    this.calendars = this.createCalendars();
  }

  prepare(): void {
    this.prepareInitial();
    this.prepareButtons();
    this.prepareEvents();
  }

  prepareInitial(): void {
    let calendar = new Gregorian();
    let currentDate = new Date();
    let hairia = calendar.toHairia(calendar.fromDate(currentDate));
    this.update(hairia);
  }

  prepareButtons(): void {
    for (let calendar of this.calendars) {
      let button = document.querySelector<HTMLInputElement>("#" + calendar.name);
      if (button) {
        button.addEventListener("click", (event) => {
          this.updateFrom(calendar);
        });
      }
    }
  }

  prepareEvents(): void {
    for (let calendar of this.calendars) {
      for (let type of ["year", "month", "day"]) {
        let element = document.querySelector<HTMLInputElement>("#" + calendar.name + "-" + type);
        if (element) {
          element.addEventListener("keydown", (event) => {
            if (event.key == "Enter") {
              this.updateFrom(calendar);
            } else if (event.key == "ArrowUp") {
              this.updateFrom(calendar, 1);
            } else if (event.key == "ArrowDown") {
              this.updateFrom(calendar, -1);
            }
          });
        }
      }
    }
  }

  getDate(calendar: Calendar): AbstractDate {
    let yearElement = document.querySelector<HTMLInputElement>("#" + calendar.name + "-year");
    let monthElement = document.querySelector<HTMLInputElement>("#" + calendar.name + "-month");
    let dayElement = document.querySelector<HTMLInputElement>("#" + calendar.name + "-day");
    let date = new AbstractDate(0, 0, 0);
    if (yearElement) {
      date.year = parseInt(yearElement.value);
    }
    if (monthElement) {
      date.month = parseInt(monthElement.value);
    }
    if (dayElement) {
      date.day = parseInt(dayElement.value);
    }
    return date;
  }

  update(hairia: Hairia): void {
    for (let calendar of this.calendars) {
      let yearElement = document.querySelector<HTMLInputElement>("#" + calendar.name + "-year");
      let monthElement = document.querySelector<HTMLInputElement>("#" + calendar.name + "-month");
      let dayElement = document.querySelector<HTMLInputElement>("#" + calendar.name + "-day");
      let date = calendar.fromHairia(hairia);
      if (yearElement) {
        yearElement.value = date.year.toString();
      }
      if (monthElement) {
        monthElement.value = date.month.toString();
      }
      if (dayElement) {
        dayElement.value = date.day.toString();
      }
    }
  }

  updateFrom(calendar: Calendar, offset: number = 0): void {
    let date = this.getDate(calendar);
    let hairia = calendar.toHairia(date) + offset;
    this.update(hairia);
  }

  createCalendars(): Calendar[] {
    let calendars = <Calendar[]>[];
    calendars.push(new OldHairian("old-hairian"));
    calendars.push(new NewHairian("new-hairian"));
    calendars.push(new Gregorian("gregorian"));
    calendars.push(new RawHairia("hairia"));
    return calendars;
  }

}


let executor = new Executor();
window.addEventListener("load", () => {
  executor.prepare();
});
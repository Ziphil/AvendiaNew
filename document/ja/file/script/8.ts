/// <reference path="C:/Users/Ziphil/AppData/Roaming/npm/node_modules/@types/jquery/index.d.ts"/>


const DICTIONARY_URL = "https://en.oxforddictionaries.com/definition/";
const PRONUNCIATION_REGEXP = "&lt;span class=\"phoneticspelling\"&gt;(.+)&lt;\/span&gt;";

type WordMark = 0 | 1 | null;


class WordEntry {

  english: string;
  japanese: string;
  mark: WordMark;

  constructor(english: string, japanese: string) {
    this.english = english;
    this.japanese = japanese;
    this.mark = null;
  }

}


class WordManager {

  entries: WordEntry[];

  constructor() {
    this.entries = [];
  }

  append(text: string): void {
    let splitText = text.split(/\r\n|\r|\n/);
    for (let i = 0 ; i < splitText.length ; i ++) {
      let line = splitText[i];
      let match = line.match(/^\s*(.+?)\s*,\s*(.+)\s*$/m);
      if (match != null) {
        let entry = new WordEntry(match[1], match[2]);
        this.entries.push(entry);
      }
    }
    this.shuffle();
  }
  
  shuffle(): void {
    let entries = this.entries;
    for (let i = entries.length - 1 ; i > 0 ; i --) {
      let j = Math.floor(Math.random() * (i + 1));
      var temporary = entries[i];
      entries[i] = entries[j];
      entries[j] = temporary;
    }
  }

  get(index: number): WordEntry {
    return this.entries[index];
  }

  get length(): number {
    return this.entries.length;
  }

}


class Executor {

  manager: WordManager;
  request: any;
  count: number;

  constructor() {
    this.manager = new WordManager();
    this.count = 0;
  }

  prepare(): void {
    $(document).on("keydown", (event) => {
      if (event.keyCode == 39) {
        let amount = (event.shiftKey) ? 2 : 1;
        this.next(amount);
      } else if (event.keyCode == 37) {
        let amount = (event.shiftKey) ? 2 : 1;
        this.previous(amount);
      }
      if (event.keyCode == 68) {
        this.mark(0);
      } else if (event.keyCode == 65) {
        this.mark(1);
      } else if (event.keyCode == 83) {
        this.mark(null);
      }
    });
    $("input[name=\"mode\"]:radio").change((event) => {
      let modeString = $(event.target).val();
      let mode = (typeof modeString == "string") ? parseInt(modeString) : 0;
      let arrowDiv = $("#arrow");
      if (mode == 0) {
        arrowDiv.css("margin", "0px auto -5px auto");
        arrowDiv.css("border-top", "30px hsl(240, 60%, 60%) solid");
        arrowDiv.css("border-right", "50px transparent solid");
        arrowDiv.css("border-bottom", "30px transparent solid");
        arrowDiv.css("border-left", "50px transparent solid");
      } else {
        arrowDiv.css("margin", "-30px auto 25px auto");
        arrowDiv.css("border-top", "30px transparent solid");
        arrowDiv.css("border-right", "50px transparent solid");
        arrowDiv.css("border-bottom", "30px hsl(240, 60%, 60%) solid");
        arrowDiv.css("border-left", "50px transparent solid");
      }
    });
    $("#show-list").change((event) => {
      this.toggleList();
    });
  }

  upload(): void {
    let manager = new WordManager();
    let fileElement = <HTMLInputElement>$("#file")[0];
    let files = fileElement.files || new FileList();
    for (let file of files) {
      let reader = new FileReader();
      reader.onload = (event) => {
        let result = reader.result;
        if (typeof result == "string") {
          manager.append(result);
          this.updateMain(true);
          this.updateMark();
          this.createList();
        } else {
          alert("テキストデータではありません。");
        }
      };
      reader.readAsText(file);
    }
    this.manager = manager;
  }

  createList(): void {
    let manager = this.manager;
    let table = $("#list");
    table.empty();
    for (let i = 0 ; i < manager.length ; i ++) {
      let entry = manager.get(i);
      let tr = $("<tr>").attr("id", "entry-" + i);
      let numberTd = $("<td>").attr("class", "number").text(i + 1);
      let markTd = $("<td>").attr("class", "mark");
      let textTd = $("<td>").attr("class", "text").text(entry.english);
      tr.on("click", (event) => {
        this.jump(i * 2 + 1);
      });
      tr.append(numberTd);
      tr.append(markTd);
      tr.append(textTd);
      table.append(tr);
    }
    for (let i = 0 ; i < manager.length ; i ++) {
      this.updateList(i);
    }
  }

  updateMain(increment: boolean): void {
    let manager = this.manager;
    let index = this.index;
    let status = (this.count + 1) % 2;
    let modeString = $("input[name=\"mode\"]:checked").val();
    let mode = (typeof modeString == "string") ? parseInt(modeString) : 0;
    let entry = manager.get(index);
    if (entry) {
      if (status == 0) {
        if (mode == 0) {
          $("#english").text(entry.english);
          $("#japanese").text("");
          $("#pronunciation").text("　");
        } else {
          $("#english").text("");
          $("#japanese").text(entry.japanese);
          $("#pronunciation").text("");
        }
      } else {
        $("#english").text(entry.english);
        $("#japanese").text(entry.japanese);
        $("#pronunciation").text("　");
      }
    } else {
      $("#english").text("");
      $("#japanese").text("");
    }
    $("#numerator").text(index + 1);
    $("#denominator").text(manager.length);
  }

  updateMark(): void {
    let manager = this.manager;
    let index = this.index;
    let entry = manager.get(index);
    if (entry) {
      let mark = entry.mark;
      if (mark == 0) {
        $("#correct-mark").show();
        $("#wrong-mark").hide();
      } else if (mark == 1) {
        $("#correct-mark").hide();
        $("#wrong-mark").show();
      } else {
        $("#correct-mark").hide();
        $("#wrong-mark").hide();
      }
    } else {
      $("#correct-mark").hide();
      $("#wrong-mark").hide();
    }
  }

  updateList(index: number): void {
    let manager = this.manager;
    let entry = manager.get(index);
    if (entry) {
      let mark = entry.mark;
      let markTd = $("#entry-" + index + " .mark");
      let textTd = $("#entry-" + index + " .text");
      if (mark == 0) {
        markTd.text("\uF009");
        markTd.attr("class", "mark correct");
        textTd.attr("class", "text correct");
      } else if (mark == 1) {
        markTd.text("\uF00A");
        markTd.attr("class", "mark wrong");
        textTd.attr("class", "text wrong");
      } else {
        markTd.text("");
        markTd.attr("class", "mark");
        textTd.attr("class", "text");
      }
    }
  }

  previous(amount: number = 1): void {
    if (this.count > 0) {
      this.count -= amount;
      if (this.count <= 0) {
        this.count = 0;
      }
      this.updateMain(false);
      this.updateMark();
    } else {
      alert("は?");
    }
  }

  next(amount: number = 1): void {
    if (this.count < this.manager.length * 2) {
      this.count += amount;
      if (this.count >= this.manager.length * 2) {
        this.count = this.manager.length * 2;
      }
      this.updateMain(true);
      this.updateMark();
    } else {
      alert("全ての問題が終了しました。");
    }
  }

  jump(count: number): void {
    if (count >= 0 && count <= this.manager.length * 2) {
      this.count = count;
      this.updateMain(false);
      this.updateMark();
    } else {
      alert("は?");
    }
  }

  reset(): void {
    let result = confirm("リセットしますか?");
    if (result) {
      this.count = 0;
      this.manager.shuffle();
      this.updateMain(false);
      this.updateMark();
      this.createList();
    }
  }

  mark(mark: WordMark): void {
    let manager = this.manager;
    let index = this.index;
    let entry = manager.get(index);
    if (entry) {
      entry.mark = mark;
      this.updateMark();
      this.updateList(index);
      if ($("#enable-sound").prop("checked")) {
        if (mark == 0) {
          let element = <HTMLMediaElement>$("#correct-sound")[0];
          element.play();
        } else if (mark == 1) {
          let element = <HTMLMediaElement>$("#wrong-sound")[0];
          element.play();
        }
      }
    } else {
      alert("それは無理。");
    }
  }

  toggleList(): void {
    if ($("#show-list").prop("checked")) {
      $("#list-wrapper").attr("class", "list shown");
    } else {
      $("#list-wrapper").attr("class", "list");
    }
  }

  fetchPronunciations(word: string, tag: JQuery<HTMLElement>): void {
    let previousRequest = this.request;
    if (previousRequest) {
      previousRequest.abort();
    }
    let url = DICTIONARY_URL + word;
    let request = $.get(url, (data) => {
      let html = data.responseText;
      let regexp = new RegExp(PRONUNCIATION_REGEXP, "g");
      let pronunciations = <string[]>[];
      let match = <RegExpExecArray | null>null;
      while ((match = regexp.exec(html)) != null) {
        pronunciations.push(match[1]);
      }
      if (pronunciations.length > 0) {
        pronunciations = pronunciations.filter((pronunciation, index, self) => {
          return self.indexOf(pronunciation) == index;
        });
        tag.text(pronunciations.join(", "));
      } else {
        tag.text("?");
      }
    });
    this.request = request;
  }

  get index(): number {
    return Math.floor((this.count + 1) / 2) - 1;
  }

}


let executor = new Executor();
$(() => {
  executor.prepare();
});
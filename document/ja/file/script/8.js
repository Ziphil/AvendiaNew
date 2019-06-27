//


const DICTIONARY_URL = "https://en.oxforddictionaries.com/definition/";
const PRONUNCIATION_REGEXP = /&lt;span class="phoneticspelling"&gt;(.+)&lt;\/span&gt;/;


class WordManager {

  constructor() {
    this.entries = [];
  }

  append(text) {
    let splitText = text.split(/\r\n|\r|\n/);
    for (let i = 0 ; i < splitText.length ; i ++) {
      let line = splitText[i];
      let match;
      if ((match = line.match(/^\s*(.+?)\s*,\s*(.+)\s*$/m)) != null) {
        let entry = {english: match[1], japanese: match[2], mark: null};
        this.entries.push(entry);
      }
    }
    this.shuffle();
  }
  
  shuffle() {
    let entries = this.entries;
    for (let i = entries.length - 1 ; i > 0 ; i --) {
      let j = Math.floor(Math.random() * (i + 1));
      var temporary = entries[i];
      entries[i] = entries[j];
      entries[j] = temporary;
    }
  }

  get(index) {
    return this.entries[index];
  }

  get length() {
    return this.entries.length;
  }

}


class Executor {

  constructor() {
    this.manager = new WordManager("");
    this.count = 0;
  }

  prepare() {
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
      let mode = parseInt($(event.target).val());
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

  upload() {
    let manager = new WordManager();
    let files = $("#file")[0].files;
    for (let file of files) {
      let reader = new FileReader();
      reader.onload = (event) => {
        manager.append(reader.result);
        this.updateMain();
        this.updateMark();
        this.createList();
      };
      reader.readAsText(file);
    }
    this.manager = manager;
  }

  createList() {
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

  updateMain(increment) {
    let manager = this.manager;
    let index = this.index;
    let status = (this.count + 1) % 2;
    let mode = parseInt($("input[name=\"mode\"]:checked").val());
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

  updateMark() {
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

  updateList(index) {
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

  previous(amount = 1) {
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

  next(amount = 1) {
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

  jump(count) {
    if (count >= 0 && count <= this.manager.length * 2) {
      this.count = count;
      this.updateMain(false);
      this.updateMark();
    } else {
      alert("は?");
    }
  }

  reset() {
    let result = confirm("リセットしますか?");
    if (result) {
      this.count = 0;
      this.manager.shuffle();
      this.updateMain(false);
      this.updateMark();
      this.createList();
    }
  }

  mark(mark) {
    let manager = this.manager;
    let index = this.index;
    let entry = manager.get(index);
    if (entry) {
      entry.mark = mark;
      this.updateMark();
      this.updateList(index);
      if ($("#enable-sound").prop("checked")) {
        if (mark == 0) {
          $("#correct-sound")[0].play();
        } else if (mark == 1) {
          $("#wrong-sound")[0].play();
        }
      }
    } else {
      alert("それは無理。");
    }
  }

  toggleList() {
    if ($("#show-list").prop("checked")) {
      $("#list-wrapper").attr("class", "list shown");
    } else {
      $("#list-wrapper").attr("class", "list");
    }
  }

  fetchPronunciations(word, tag) {
    let previousRequest = this.request;
    if (previousRequest) {
      previousRequest.abort();
    }
    let url = DICTIONARY_URL + word;
    let request = $.get(url, (data) => {
      let html = data.responseText;
      let regexp = new RegExp(PRONUNCIATION_REGEXP, "g");
      let pronunciations = [];
      let match;
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

  get index() {
    return Math.floor((this.count + 1) / 2) - 1;
  }

}


let executor = new Executor();
$(() => {
  executor.prepare();
});
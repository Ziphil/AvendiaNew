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
  }

  upload() {
    let manager = new WordManager();
    let files = $("#file")[0].files;
    for (let file of files) {
      let reader = new FileReader();
      reader.onload = (event) => {
        manager.append(reader.result);
        this.update();
      };
      reader.readAsText(file);
    }
    this.manager = manager;
  }

  update(increment) {
    let manager = this.manager;
    let index = Math.floor((this.count + 1) / 2) - 1;
    let status = (this.count + 1) % 2;
    let mode = parseInt($("input[name=\"mode\"]:checked").val());
    let entry = manager.get(index);
    if (entry) {
      if (status == 0) {
        if (mode == 0) {
          $("#english").text(entry.english);
          $("#japanese").text("");
          $("#pronunciation").text("　");
          if (increment) {
            this.fetchPronunciations(entry.english, $("#pronunciation"));
          }
        } else {
          $("#english").text("");
          $("#japanese").text(entry.japanese);
          $("#pronunciation").text("");
        }
      } else {
        $("#english").text(entry.english);
        $("#japanese").text(entry.japanese);
        $("#pronunciation").text("　");
        if ((mode == 0 && !increment) || mode == 1) {
          this.fetchPronunciations(entry.english, $("#pronunciation"));
        }
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
    let index = Math.floor((this.count + 1) / 2) - 1;
    let entry = manager.get(index);
    if (entry) {
      let mark = entry.mark;
      if (mark == "correct") {
        $("#correct-mark").show();
        $("#wrong-mark").hide();
      } else if (mark == "wrong") {
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

  previous(amount = 1) {
    if (this.count > 0) {
      this.count -= amount;
      if (this.count <= 0) {
        this.count = 0;
      }
      this.update(false);
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
      this.update(true);
      this.updateMark();
    } else {
      alert("全ての問題が終了しました。");
    }
  }

  reset() {
    let result = confirm("リセットしますか?");
    if (result) {
      this.count = 0;
      this.manager.shuffle();
      this.update(false);
      this.updateMark();
    }
  }

  markCorrect() {
    let manager = this.manager;
    let index = Math.floor((this.count + 1) / 2) - 1;
    let entry = manager.get(index);
    if (entry) {
      entry.mark = "correct";
      this.updateMark();
      if ($("#enable-sound").prop("checked")) {
        $("#correct-sound")[0].play();
      }
    } else {
      alert("それは無理。");
    }
  }

  markWrong() {
    let manager = this.manager;
    let index = Math.floor((this.count + 1) / 2) - 1;
    let entry = manager.get(index);
    if (entry) {
      entry.mark = "wrong";
      this.updateMark();
      if ($("#enable-sound").prop("checked")) {
        $("#wrong-sound")[0].play();
      }
    } else {
      alert("それは無理。");
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

}


let executor = new Executor();
$(() => {
  executor.prepare();
});
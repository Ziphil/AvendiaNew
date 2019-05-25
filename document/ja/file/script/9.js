//


const RADIX = 16;
const HIGHLIGHT_COLOR = "hsl(240, 60%, 60%)"
const HIGHLIGHT_BACKGROUND_COLOR = "hsl(240, 100%, 98%)"


class Executor {

  constructor() {
    this.status = 0;
    this.previousInput = {left: "", right: ""};
  }

  prepare() {
    $("input[name=\"left-mode\"]:radio").change((event) => {
      this.createTable();
    });
    $("input[name=\"right-mode\"]:radio").change((event) => {
      this.createTable();
    });
    this.previousInput.left = $("#left").val();
    this.previousInput.right = $("#right").val();
    this.createTable();
  }

  changeOperator() {
    let operatorButton = $("#operator");
    if (operatorButton.val() == "+") {
      operatorButton.val("×");
    } else {
      operatorButton.val("+")
    }
    if (this.status == 1) {
      this.updateAnswer();
    }
    this.createTable();
  }
  
  toggleTable() {
    let tableContainer = $("#table-container");
    if (tableContainer.is(":visible")) {
      $("#show").text("Show Table");
      tableContainer.hide();
    } else {
      $("#show").text("Hide Table");
      tableContainer.show();
    }
  }

  validateInput(source) {
    let id = source.attr("id");
    let input = source.val().toUpperCase();
    if (input.length <= 1) {
      let maxAlphabet = (RADIX - 1).toString(RADIX).toUpperCase();
      let correctRegexp = new RegExp("^[1-9A-" + maxAlphabet + "]{0,1}$");
      if (input.match(correctRegexp)) {
        source.val(input);
        this.previousInput[id] = input;
      } else {
        source.val(this.previousInput[id]);
      }
    } else {
      let maxAlphabet = (RADIX - 1).toString(RADIX).toUpperCase();
      let correctRegexp = new RegExp("^[1-9A-" + maxAlphabet + "]$");
      let lastCharacter = input.slice(-1);
      if (lastCharacter.match(correctRegexp)) {
        source.val(lastCharacter);
        this.previousInput[id] = lastCharacter;
      } else {
        source.val(this.previousInput[id]);
      }
    }
    if (this.status == 1) {
      this.updateAnswer();
    }
    this.createTable();
  }

  next() {
    if (this.status == 0) {
      this.updateAnswer();
      this.status = 1;
    } else {
      this.incrementProblem();
      this.status = 0;
    }
  }

  updateAnswer() {
    let left = parseInt($("#left").val(), RADIX) || 1;
    let right = parseInt($("#right").val(), RADIX) || 1;
    let answer = ($("#operator").val() == "+") ? left + right : left * right;
    $("#answer").text(answer.toString(RADIX).toUpperCase());
  }

  incrementProblem() {
    let left = parseInt($("#left").val(), RADIX) || 1;
    let right = parseInt($("#right").val(), RADIX) || 1;
    let nextLeft = left;
    let nextRight = right;
    let leftMode = parseInt($("input[name=\"left-mode\"]:checked").val());
    let rightMode = parseInt($("input[name=\"right-mode\"]:checked").val());
    if (leftMode == 0) {
      nextLeft = left + 1;
      if (nextLeft > RADIX - 1) {
        nextLeft = 1;
      }
    } else if (leftMode == 1) {
      nextLeft = left - 1;
      if (nextLeft < 1) {
        nextLeft = RADIX - 1;
      }
    } else if (leftMode == 2) {
      while (nextLeft == left) {
        nextLeft = Math.floor(Math.random() * (RADIX - 1)) + 1;
      }
    }
    if (rightMode == 0) {
      nextRight = right + 1;
      if (nextRight > RADIX - 1) {
        nextRight = 1;
      }
    } else if (rightMode == 1) {
      nextRight = right - 1;
      if (nextRight < 1) {
        nextRight = RADIX - 1;
      }
    } else if (rightMode == 2) {
      while (nextRight == right) {
        nextRight = Math.floor(Math.random() * (RADIX - 1)) + 1;
      }
    }
    $("#left").val(nextLeft.toString(RADIX).toUpperCase());
    $("#right").val(nextRight.toString(RADIX).toUpperCase());
    $("#answer").text("");
  }

  createTable() {
    let left = parseInt($("#left").val(), RADIX) || 1;
    let right = parseInt($("#right").val(), RADIX) || 1;
    let leftMode = parseInt($("input[name=\"left-mode\"]:checked").val());
    let rightMode = parseInt($("input[name=\"right-mode\"]:checked").val());
    let table = $("#table");
    table.empty();
    for (let i = 0 ; i <= RADIX - 1 ; i ++) {
      let tr = $("<tr>");
      for (let j = 0 ; j <= RADIX - 1 ; j ++) {
        let td = (i >= 1 && j >= 1) ? $("<td>") : $("<th>");
        if (i == 0 && j == 0) {
          td.text($("#operator").val());
        } else if (i == 0) {
          td.text(j.toString(RADIX).toUpperCase());
        } else if (j == 0) {
          td.text(i.toString(RADIX).toUpperCase());
        } else {
          let answer = ($("#operator").val() == "+") ? i + j : i * j;
          td.text(answer.toString(RADIX).toUpperCase());
        }
        if (i == 0 && j != 0) {
          td.on("click", (event) => {
            $("#right").val(td.text());
            if (this.status == 1) {
              this.updateAnswer();
            }
            this.createTable();
          });
        } else if (j == 0 && i != 0) {
          td.on("click", (event) => {
            $("#left").val(td.text());
            if (this.status == 1) {
              this.updateAnswer();
            }
            this.createTable();
          });
        }
        if (leftMode == 3) { 
          if ((rightMode != 3 || (rightMode == 3 && j == right)) && i == left - 1) {
            td.css("border-bottom", "1px " + HIGHLIGHT_COLOR + " solid");
          } else if ((rightMode != 3 || (rightMode == 3 && j == right)) && i == left) {
            td.css("border-bottom", "1px " + HIGHLIGHT_COLOR + " solid");
            td.css("font-weight", "bold");
            td.css("color", HIGHLIGHT_COLOR);
            td.css("background-color", HIGHLIGHT_BACKGROUND_COLOR);
            if (j == 0) {
              td.css("border-right", "1px " + HIGHLIGHT_COLOR + " solid");
              td.css("color", "white");
              td.css("background-color", HIGHLIGHT_COLOR);
            }
          }
          if (rightMode != 3 && i == left && j == RADIX - 1) {
            td.css("border-right", "1px " + HIGHLIGHT_COLOR + " solid");
          }
        }
        if (rightMode == 3) {
          if ((leftMode != 3 || (leftMode == 3 && i == left)) && j == right - 1) {
            td.css("border-right", "1px " + HIGHLIGHT_COLOR + " solid");
          } else if ((leftMode != 3 || (leftMode == 3 && i == left)) && j == right) {
            td.css("border-right", "1px " + HIGHLIGHT_COLOR + " solid");
            td.css("font-weight", "bold");
            td.css("color", HIGHLIGHT_COLOR);
            td.css("background-color", HIGHLIGHT_BACKGROUND_COLOR);
            if (i == 0) {
              td.css("border-bottom", "1px " + HIGHLIGHT_COLOR + " solid");
              td.css("color", "white");
              td.css("background-color", HIGHLIGHT_COLOR);
            }
          }
          if (leftMode != 3 && j == right && i == RADIX - 1) {
            td.css("border-bottom", "1px " + HIGHLIGHT_COLOR + " solid");
          }
        }
        tr.append(td);
      }
      table.append(tr);
    }
  }

}


let executor = new Executor();
$(() => {
  executor.prepare();
});
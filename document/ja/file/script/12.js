//


DICTIONARY_URL = "conlang/database/1.cgi"

function prepare() {
  $.get(DICTIONARY_URL, {mode: "fetch", type: "1"}, (result) => {
    $("#whole-count").text(result);
  });
  $.get(DICTIONARY_URL, {mode: "fetch", type: "3", agree: "7"}, (result) => {
    $("#week-count").text(result);
  });
  $.get(DICTIONARY_URL, {mode: "fetch", type: "3", agree: "30"}, (result) => {
    $("#month-count").text(result);
  });
}

$(prepare);
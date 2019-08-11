//


DICTIONARY_URL = "conlang/database/1.cgi"

function prepare() {
  $.get(DICTIONARY_URL, {mode: "fetch", type: "1"}, (data) => {
    $("#whole-count").text(data);
  });
}

$(prepare);
//


function setup() {
  $("[name=\"search\"]").on("keyup", () => {
    let text;
    let newText;
    if ($("[name=\"conversion\"]").prop("checked") && $("[name=\"version\"]").val() == "0") {
      text = $("[name=\"search\"]").val();
      newText = text;
      newText = newText.replace(/aa/g, "â");
      newText = newText.replace(/ee/g, "ê");
      newText = newText.replace(/ii/g, "î");
      newText = newText.replace(/oo/g, "ô");
      newText = newText.replace(/uu/g, "û");
      newText = newText.replace(/ai/g, "á");
      newText = newText.replace(/ei/g, "é");
      newText = newText.replace(/ie/g, "í");
      newText = newText.replace(/au/g, "à");
      newText = newText.replace(/eu/g, "è");
      newText = newText.replace(/iu/g, "ì");
      newText = newText.replace(/oa/g, "ò");
      newText = newText.replace(/ua/g, "ù");
      if (text != newText) {
        $("[name=\"search\"]").val(newText);
      }
    }
  });
  $("[name=\"word\"]").on("keyup", () => {
    let text;
    let newText;
    if (true) {
      text = $("[name=\"word\"]").val();
      newText = text;
      newText = newText.replace(/aa/g, "â");
      newText = newText.replace(/ee/g, "ê");
      newText = newText.replace(/ii/g, "î");
      newText = newText.replace(/oo/g, "ô");
      newText = newText.replace(/uu/g, "û");
      newText = newText.replace(/ai/g, "á");
      newText = newText.replace(/ei/g, "é");
      newText = newText.replace(/ie/g, "í");
      newText = newText.replace(/au/g, "à");
      newText = newText.replace(/eu/g, "è");
      newText = newText.replace(/iu/g, "ì");
      newText = newText.replace(/oa/g, "ò");
      newText = newText.replace(/ua/g, "ù");
      if (text != newText) {
        $("[name=\"word\"]").val(newText);
      }
    }
  });
  if ($("[name=\"word\"]")[0]) {
    $("[name=\"content\"]").focus();
  } else {
    $("[name=\"search\"]").focus();
  }
}

$(setup);
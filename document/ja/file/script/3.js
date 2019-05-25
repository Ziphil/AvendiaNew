//


function setup() {
  $("[name=\"word\"]").on("keyup", () => {
    let text = $("[name=\"word\"]").val();
    let newText;
    if (!~text.indexOf("#")) {
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
}

$(setup);
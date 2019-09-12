//


export function prepare(): void {
  let element = document.querySelector<HTMLInputElement>("[name=\"search\"]")!;
  element.addEventListener("keyup", (event) => {
    let text = element.value;
    let nextText = convert(text);
    if (text !== nextText) {
      element.value = nextText;
    }
  });
  element.focus();
}

export function convert(text: string): string {
  let nextText = text;
  nextText = nextText.replace(/aa/g, "â");
  nextText = nextText.replace(/ee/g, "ê");
  nextText = nextText.replace(/ii/g, "î");
  nextText = nextText.replace(/oo/g, "ô");
  nextText = nextText.replace(/uu/g, "û");
  nextText = nextText.replace(/ai/g, "á");
  nextText = nextText.replace(/ei/g, "é");
  nextText = nextText.replace(/ie/g, "í");
  nextText = nextText.replace(/au/g, "à");
  nextText = nextText.replace(/eu/g, "è");
  nextText = nextText.replace(/iu/g, "ì");
  nextText = nextText.replace(/oa/g, "ò");
  nextText = nextText.replace(/ua/g, "ù");
  return nextText;
}

window.onload = prepare;
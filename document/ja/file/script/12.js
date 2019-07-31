//


const ALTERNATIVE_URL = "other/other/13.html";

function redirect() {
  let agent = navigator.userAgent;
  if ((agent.indexOf("iPhone") >= 0 && agent.indexOf("iPad") == -1) || agent.indexOf("iPod") >= 0 || agent.indexOf("Android") >= 0) {
    location.href = ALTERNATIVE_URL;
  }
}

redirect();
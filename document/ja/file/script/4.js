//


function download(url, name) {
  let request = new XMLHttpRequest();
  request.open("GET", url, true);
  request.responseType = "blob";
  request.onload = (event) => {
    let blob = request.response;
    if (window.navigator.msSaveBlob) {
      window.navigator.msSaveBlob(blob, name);
    } else {
      let objectURL = window.URL.createObjectURL(blob);
      let link = document.createElement("a");
      document.body.appendChild(link);
      link.href = objectURL;
      link.download = name;
      link.click();
      document.body.removeChild(link);
    }
  };
  request.send();
}
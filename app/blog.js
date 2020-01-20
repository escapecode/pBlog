var oDoc, sDefTxt;

function initDoc() {
	console.log('initDoc');
  oDoc = document.getElementById("content1");
  sDefTxt = oDoc.innerHTML;
  if (document.submitform.switchMode.checked) { setDocMode(true); }
}

function formatDoc(sCmd, sValue) {
	console.log('format doc ' + sCmd + ' ' + sValue)
  if (validateMode())
  {
		document.execCommand(sCmd, false, sValue); oDoc.focus();
	}
}

function validateMode() {
  if (!document.submitform.switchMode.checked) { return true ; }
  alert("Uncheck \"Show HTML\".");
  oDoc.focus();
  return false;
}

function setDocMode(bToSource) {
  var oContent;
  if (bToSource) {
	oContent = document.createTextNode(oDoc.innerHTML);
	oDoc.innerHTML = "";
	var oPre = document.createElement("pre");
	oDoc.contentEditable = false;
	oPre.id = "sourceText";
	oPre.contentEditable = true;
	oPre.appendChild(oContent);
	oDoc.appendChild(oPre);
	document.execCommand("defaultParagraphSeparator", false, "div");
  } else {
	if (document.all) {
	  oDoc.innerHTML = oDoc.innerText;
	} else {
	  oContent = document.createRange();
	  oContent.selectNodeContents(oDoc.firstChild);
	  oDoc.innerHTML = oContent.toString();
	}
	oDoc.contentEditable = true;
  }
  oDoc.focus();
}

function printDoc() {
  if (!validateMode()) { return; }
  var oPrntWin = window.open("","_blank","width=450,height=470,left=400,top=100,menubar=yes,toolbar=no,location=no,scrollbars=yes");
  oPrntWin.document.open();
  oPrntWin.document.write("<!doctype html><html><head><title>Print<\/title><\/head><body onload=\"print();\">" + oDoc.innerHTML + "<\/body><\/html>");
  oPrntWin.document.close();
}

function imageUpload(evt) {
	var files = evt.target.files; // FileList object

	// Loop through the FileList and render image files as thumbnails.
	for (var i = 0, f; f = files[i]; i++) {

	  // Only process image files.
	  if (!f.type.match('image.*')) {
		continue;
	  }

	  var reader = new FileReader();

	  // Closure to capture the file information.
	  reader.onload = (function(theFile) {
		return function(e) {
		  // Render thumbnail.
		  formatDoc('insertImage', e.target.result)
		};
	  })(f);

	  // Read in the image file as a data URL.
	  reader.readAsDataURL(f);
	}
}

window.addEventListener ? addEventListener("load", initDoc, false) : window.attachEvent ? attachEvent("onload", initDoc) : window.onload = initDoc;

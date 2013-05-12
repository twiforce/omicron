//= require jquery
//= require jquery_ujs
//
//= require form
//= require hotkeys
//= require scrollto
//= require caret
//= require fields
//
//= require threads

function getSelectedText() {
  var text = "";
  if (getSelection) {
    text = getSelection().toString();
  } else if (document.selection && document.selection.type != "Control") {
    text = document.selection.createRange().text;
  }
  return text
}



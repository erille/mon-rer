var autocomp_form;
var autocomp_field;
var autocomp_submit;
var autocomp_results;

var autocomp_timer;

var autocomp_cur_input_val = ''; // courant
var autocomp_old_input_val = ''; // avant la dernière touche
var autocomp_orig_input_val = ''; // avant le clic

var autocomp_last_keycode;

var autocomp_cache = {};
var autocomp_xmlhttp;

var autocomp_display_list;
var autocomp_hl_index = -1;

var autocomp_input_volatile = 1;
var autocomp_escaping = 0;

function init_autocomp(form, field, combo, results, submit) {
	autocomp_form = document.getElementById(form);
	autocomp_field = document.getElementById(field);
	autocomp_results = document.getElementById(results);
	autocomp_submit = document.getElementById(submit);
	document.getElementById(combo).style.display = 'none';
	
	autocomp_cur_input_val = autocomp_field.value;
	autocomp_old_input_val = autocomp_field.value;
	autocomp_field.autocomplete = "off";
	autocomp_field.onkeyup = autocomp_keyup;
	autocomp_field.onclick = function() { 
		autocomp_escaping = 0;
		autocomp_orig_input_val = autocomp_field.value;
		autocomp_field.value = ''; 
	};
	autocomp_field.onblur = function() {
		autocomp_escaping = 1;
		autocomp_field.value = autocomp_orig_input_val;
		autocomp_show(0);
	}
	autocomp_field.onfocus = function() { autocomp_field.select(); };

	autocomp_submit.style.display = "none";
	autocomp_submit.onclick = function(e) { e.preventDefault(); return false; };
	autocomp_form.onsubmit = function(e) { e.preventDefault(); return false; };

	autocomp_display_list = document.createElement('ul');
	autocomp_results.appendChild(autocomp_display_list);
	autocomp_show(0);

	autocomp_results.style.left = calculateOffsetLeft(autocomp_field) + "px";

	document.onkeydown = autocomp_keydown;

	setTimeout(autocomp_loop, 200);
}

function autocomp_show(b) {
	autocomp_results.style.display = b ? 'block' : 'none';
}


function autocomp_get(str) {
	if (!str)
		return;

	if (autocomp_xmlhttp && autocomp_xmlhttp.readyState != 0) 
		autocomp_xmlhttp.abort();
	
	autocomp_xmlhttp = new XMLHttpRequest();
	autocomp_xmlhttp.open("GET", "autocomp?s=" + str, true);
	autocomp_xmlhttp.onreadystatechange = function() {
		if (autocomp_xmlhttp.readyState == 4) {
			var list = JSON.parse(autocomp_xmlhttp.responseText);
			autocomp_store_cache(str, list);
			autocomp_set(list);
		}
	};

	autocomp_xmlhttp.send(null);
}

function autocomp_store_cache(str, list) {
	autocomp_cache[str] = list;
}

function autocomp_make_click_handler(c, n) {
	return function() {
		autocomp_field.value = n;
		autocomp_old_input_val = n;
		autocomp_orig_input_val = n;
		autocomp_field.blur();
		autocomp_show(0);
		change_station(c, n, 1);
		autocomp_input_volatile = 1;
		return false;
	};
}



function autocomp_line_images(lines) {
	if (!lines)
		return;

	var result = "";
	for (var i = 0; i < lines.length; i++) {
		result = result + '<img src="img/rer'
			+ lines[i] + '.svg" alt="'
			+ lines[i] + '" />';
	}
	return result;
}

function autocomp_set(list) {
	while (autocomp_display_list.childNodes.length > 0) 
		autocomp_display_list.removeChild(autocomp_display_list.childNodes[0]);
	
	if (list.length == 0)
		autocomp_show(0);

	for (var i = 0; i < list.length; i++) {
		var n = document.createElement("li");
		var name = list[i].name;
		var code = list[i].code;

		n.innerHTML = '<span class="name">'
			+ name
			+ '\u00a0<span class="lines">'
			+ autocomp_line_images(list[i].lines)
			+ '</span></span><span class="trig">'
			+ code
			+ '</span>';
		n.onclick = autocomp_make_click_handler(code, name);
		n.onmouseover = function(i) {
			return function() {
				autocomp_set_highlight(i);
			};
		}(i);
		n.onmouseout = function() { autocomp_set_highlight(-1); };
		autocomp_display_list.appendChild(n);
	}

	autocomp_set_highlight(0);
	autocomp_show(1);

}

function autocomp_loop() {

	autocomp_cur_input_val = autocomp_field.value;
	if (!autocomp_escaping && autocomp_old_input_val != autocomp_cur_input_val) {
		var v = encodeURIComponent(autocomp_cur_input_val);
		var s = autocomp_cache[autocomp_cur_input_val];
		if (s)
			autocomp_set(s);
		else 
			autocomp_get(v);
		autocomp_field.focus();
	}
	autocomp_old_input_val = autocomp_cur_input_val;
	window.setTimeout(autocomp_loop, 200);
	return true;
}


function autocomp_keydown(event) {
	if (!event && window.event)
		event=window.event;
	if (event) 
		autocomp_last_keycode = event.keyCode;
}

function autocomp_keyup(event) {
	var keycode;

	if (!event && window.sevent)
		event = window.event;
	if (event)
		keycode = event.keyCode;

	if (keycode == 40 || keycode == 38) {
//		blurThenGetFocus();
		if (keycode == 40)
			autocomp_set_highlight_down();
		if (keycode == 38)
			autocomp_set_highlight_up();
	}

/*
	var N = rangeSize(autocomp_field);
	var v = beforeRangeSize(autocomp_field);
	var V = autocomp_field.value;
	

*/
	if (keycode != 0) {
		/*
		if (N > 0 && v != -1) {
			V = V.substring(0, v);
		}
		*/
		if (keycode == 13 || keycode == 3) {
			autocomp_display_list.childNodes[autocomp_hl_index].onclick();
		}
		else if (keycode == 27) {
			autocomp_field.value = autocomp_orig_input_val;
			autocomp_field.blur();
		}
		/*
		else {
			if (autocomp_field.value != V)
				autocomp_field.value = V;
		}
		*/
	}

	return false;
}

function autocomp_set_highlight(index) {
	for (var i = 0; i < autocomp_display_list.childNodes.length; i++) {
		if (i == autocomp_hl_index)
			autocomp_display_list.childNodes[i].className = "";
		if (i == index)
			autocomp_display_list.childNodes[i].className = "autocompItemHilight";
	}
	autocomp_hl_index = index;
}

function autocomp_set_highlight_up() {
	var index = (autocomp_hl_index <= 0) ? 0 : autocomp_hl_index - 1;
	autocomp_set_highlight(index);
}
function autocomp_set_highlight_down() {
	var index = (autocomp_hl_index >= autocomp_display_list.childNodes.length - 1) 
		? autocomp_display_list.childNodes.length - 1 
		: autocomp_hl_index + 1;
	autocomp_set_highlight(index);
}

// calcule le décalage à gauche
function calculateOffsetLeft(r){
  return calculateOffset(r,"offsetLeft")
}
 
// calcule le décalage vertical
function calculateOffsetTop(r){
  return calculateOffset(r,"offsetTop")
}
 
function calculateOffset(r,attr){
  var kb=0;
  while(r){
    kb+=r[attr];
    r=r.offsetParent
  }
  return kb
}


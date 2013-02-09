/* 
 * gladbooks.js - main gladbooks javascript functions
 *
 * this file is part of GLADBOOKS
 *
 * Copyright (c) 2012, 2013 Brett Sheffield <brett@gladbooks.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program (see the file COPYING in the distribution).
 * If not, see <http://www.gnu.org/licenses/>.
 */

var g_authurl = '/auth/';
var g_resourcedefaultsurl = '/defaults/';
var g_username = '';
var g_password = 'disabled'; /* FIXME: temporarily disabled */
var g_loggedin = false;
var g_accttype = {
	"a":"asset",
	"l":"liability",
	"c":"capital",
	"r":"revenue",
	"e":"expenditure"
}
var g_max_ledgers_per_journal=3;
var g_frmLedger;
var g_tabid = 0;

$(document).ready(function() {

	/* no password, display login dialog */
	if (g_password == '') { displayLoginBox(); }

	/* prepare tabbed workarea */
	deployTabs();

	/* reload when logo clicked */
	$("img#logo").click(function(event) {
		event.preventDefault();
		$(this).fadeTo("slow", 0, function(){location.reload(true);});
	});     

	/* set up login box */
	$("form.signin :input").bind("keydown", function(event) {
		// handle enter key presses in input boxes
		var keycode = (event.keyCode ? event.keyCode : (event.which ? event.which : event.charCode));
		if (keycode == 13) { // enter key pressed
			// submit form
			document.getElementById('btnLogin').click();
			event.preventDefault();
		}
	});

	$('a.logout-window').click(function() {
		logout();
		displayLoginBox();
	});

	$('button.submit').click(function() {
		// grab those login details and save for later
		g_username = $('input:text[name=username]').val();
		g_password = $('input:password[name=password]').val();
		auth_check();
	});
	
	$(window).unload(function() {
		logout();
	});

});

/* 
 * auth_check()
 *
 * Request an auth required page to test login credentials.
 * If successful, we can consider this user logged in.
 * Else, chuck them back to the login page with an error
 * NB: we send Authorization: 'Silent' instead of 'Basic' to 
 * prevent the browser popping up an auth dialog.
 */
function auth_check()
{
	$.ajax({
		url: g_authurl + g_username + '.xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(data) { loginok(data); },
		error: function(data) { loginfailed(); },
	});
}

/* Prepare authentication hash */
function auth_encode(username, password) {
	var tok = username + ':' + password;
	var hash = Base64.encode(tok);
	return hash;
}

/* prepare tabbed workarea */
function deployTabs() {
	//$('#tabs').tabs({ collapsable: false, heightStyle: "fill" });
	$('.tabcloser').click(function(event) {
		event.preventDefault();
		closeTab($(this).attr('href'));
	});

	addTab("Lord Such", "<p>Screaming</p>");
	addTab("Lady Such", "<p>Wailing</p>");
	addTab("Jean Paul Satre", "<p>Egad, seriously?</p>");
}

function addTab(title, content) {
	var tabid = g_tabid++;

	/* add tab and closer */
	$('ul.tablist').append('<li id="tabli' + tabid
		+ '" class="tablet' + tabid + '">'
		+ '<a href="#tab' + tabid + '">' + title + '</a>'
		+ '<a id="tabcloser' + tabid + '" class="tabcloser" href="#tab'
		+ tabid  + '">'
		+ 'X</a></li>');

	/* add content */
	$('div.tabcontent').append('<div id="tab' + tabid + '" class="tablet '
		+ 'tablet' + tabid + '">');
	$('div#tab' + tabid).append(content);

	/* add closer event */
    $('#tabcloser' + tabid).click(function(event) {
		event.preventDefault();
		closeTab(tabid);
	});

	$(".tabs li").click(function(event) {
		event.preventDefault();
		var selected_tab = $(this).find("a").attr("href");
		activateTab(selected_tab);
	});
	
	/* activate our new tab */
	activateTab(tabid);

	/* fade in if we aren't already visible */
	$('div.tabs').fadeIn(300);
}

function activateTab(tabid) {
        /* remove "active" styling from all tabs */
        $(".tabheaders li").removeClass('active');
        $(".tablet").removeClass('active');

        /* mark selected tab as active */
        $(".tablet" + tabid).addClass("active");

}

/* remove a tab */
function closeTab(tabid) {
	var tabcount = $('div#tabs').find('div').size();

	/* remove tab and content - call me in the morning if pain persists */
	$('.tablet' + tabid).remove();

	/* if we have tabs left, fade out */
	if (tabcount == 1) {
		$('div#tabs').fadeOut(300);
	}

}

/* Add Authentication header with logged-in user's credentials */
function setAuthHeader(xhr) {
	var hash = auth_encode(g_username, g_password);
	xhr.setRequestHeader("Authorization", "Silent " + hash);
}

/* login successful, do successful things */
function loginok(data) {
	g_loggedin = true;
	hideLoginBox();
	getMenu();
}

/* Login failed - inform user */
function loginfailed() {
	g_password = '';
	g_loggedin = false;
	alert("Login incorrect");
	setFocusLoginBox();
}

/* logout() - Clear password and mark user logged out.  */
function logout()
{
	/* remove user menus */
	dropMenu();

	/* clear working area */
	$("div#pagearea").empty();

	/* clear password */
	g_password = '';
	g_loggedin = false;
	$('input:password[name=password]').val('');
}

/* 
 * displayLoginBox()
 *
 * Display login dialog.  
 *
 * Based on:
 *   http://www.alessioatzeni.com/blog/login-box-modal-dialog-window-with-css-and-jquery/
 */
function displayLoginBox() {
	var loginBox = "#login-box";

	// we have the username already - grab it so focus is set properly later
	g_username = $('input:text[name=username]').val();

	// Fade in the Popup, setting focus when done
	$(loginBox).fadeIn(300, function () { setFocusLoginBox(); });
	
	// Set the center alignment padding + border see css style
	var popMargTop = ($(loginBox).height() + 24) / 2; 
	var popMargLeft = ($(loginBox).width() + 24) / 2; 
	
	$(loginBox).css({ 
		'margin-top' : -popMargTop,
		'margin-left' : -popMargLeft
	});
	
	// Add the mask to body
	$('body').append('<div id="mask"></div>');
	$('#mask').fadeIn(300);

};

function setFocusLoginBox() {
	// if username is blank, set focus there, otherwise set it to password
	if (g_username == '') {
		$("#username").focus();
	} else {
		$("#password").focus();
	}
};

function hideLoginBox() {
	$('#mask , .login-popup').fadeOut(300 , function() {
		$('#mask').remove();  
	}); 
}

function getMenu() {
	$.ajax({
		url: g_authurl + g_username +  ".xml",
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { setMenu(xml); },
		error: function(xml) { setMenu(xml); },
	});
}

function dropMenu() {
	/* move Logout out of the way */
	$logout = $('a#logout').detach();

	/* delete the rest of the menu contents */
	$("div#menudiv").empty();

	/* put Logout back, but clear */
	$("div#menudiv").append($logout);
	$('a#logout').text('');
}

function setMenu(xml) {
	/* move Logout out of the way */
	$logout = $('a#logout').detach();

	/* load xml with user's menus */
	$(xml).find("login").find("menu").each(function() {
		var item = $(this).attr("item");
		var tip = $(this).attr("tooltip");
		var href = $(this).attr("href");
		var n = $('<a href="'+ href +'" title="'+ tip +'">'+ item +'</a>');
		$(n).on("click", { url: href }, clickMenu);
		$("div#menudiv").append(n);
	});

	/* finally, add back Logout menu item */
	$("div#menudiv").append($logout);
	$('a#logout').text('Logout (' + g_username  + ')' );
}

/* grab menu event and fetch content in the background */
function clickMenu(event) {
	event.preventDefault();

	/* fadeout whatever is on the page already */
	$('div#pagearea').children().fadeOut(300);

	if ($(this).attr("href") == '#journal') {
		showJournalForm();
		return;
	}
	showSpinner();
	$.get($(this).attr("href"), 0, displayResultsGeneric, "xml");
}

/* display XML results as a sortable table */
function displayResultsGeneric(xml) {
	//$("div#pagearea").empty();
	$t = "<table class=\"datatable\">";
	$t += "<thead>";
	$t += "<tr>";
	var row = 0;
	$(xml).find('row').each(function() {
		row += 1;
		if (row == 1) {
			$(this).children().each(function() {
				$t += "<th>" + this.tagName + "</th>";
			});
			$t += "</tr>";
			$t += "</thead>";
			$t += "<tbody>";
		}
		if (row % 2 == 0) {
			$t += "<tr class=\"even\">";
		} else {
			$t += "<tr class=\"odd\">";
		}
		$(this).children().each(function() {
			$t += "<td>" + $(this).text() + "</td>";
		});
		$t += "</tr>";
	});
	$t += "</tbody>";
	$t += "</table>";

	//$("div#pagearea").append($t);
	addTab("Results", $($t));

	/* make our table pretty and sortable */
	$(".datatable").tablesorter({
		sortList: [[0,0], [1,0]], 
		widgets: ['zebra'] 
	});

	hideSpinner();
}

/* hide please wait dialog */
function hideSpinner() {
	$("#loading-div-background").hide();
}

/* show please wait dialog and spinner animation */
function showSpinner() {
	$("#loading-div-background").show();
}

/* Populate Accounts Drop-Downs with XML Data */
function populateAccountsDDowns(xml) {
	$('select.account').append($("<option />").val(0).text('<select account>'));
	$(xml).find('row').each(function() {
		var accountid = $(this).find('id').text();
		var accounttype = $(this).find('type').text();
		var accountdesc = accountid + " - " +
		$(this).find('description').text() +" ("+ g_accttype[accounttype] +")";

		$('select.account').append($("<option />").val(accountid).text(accountdesc));
	});

	finishJournalFormSetup();
}

function populateAccountTypeDDowns() {
	$('select.type').append($("<option />").val('debit').text('debit'));
	$('select.type').append($("<option />").val('credit').text('credit'));
}

/* set up journal form */
function showJournalForm() {

	dlgJournal = $('div#pagearea').dialog();

	/* load dropdown contents */
	$.get('/test/accounts/', populateAccountsDDowns, "xml");
	populateAccountTypeDDowns();

	/* set up click() events */
	$('button#journalsubmit').click(submitJournalEntry);

}

function finishJournalFormSetup() {
	var ledger_lines = 1;
	/* grab a copy of the ledger form with default values and events set */
	g_frmLedger = $('fieldset.ledger').clone(true, true);

	/* lay out some blank ledger lines */
	while (ledger_lines < g_max_ledgers_per_journal) {
		$('form.journalform').append(g_frmLedger.clone(true, true));
		ledger_lines++;
	}

	/* copy the form to the working area */
	$('div#pagearea').append($('div#dataformdiv').clone(true, true));

	/* fade in the form */
	//$('div#dataformdiv').fadeIn(300);

	/* set focus */
	$("input.description").focus();
}

function validateJournalEntry() {
	var xml = '<journal/>';
	var account;
	var type;
	var amount;
	var debits = 0;
	var credits = 0;
	$('p.journalstatus').text("");
	$('form.journalform').find('fieldset').children().each(function() {
		if ($(this).hasClass('description')) {
			/* ensure we have a description */
			if ($(this).val().trim().length == 0) {
				$('p.journalstatus').text("A description is required");
				xml = false;
				return false;
			}
			xml = '<journal description="'+ $(this).val().trim() +'">';
		}
		else if ($(this).hasClass('account')) {
			account = $(this).val();
		}
		else if ($(this).hasClass('type')) {
			type = $(this).val();
		}
		else if ($(this).hasClass('amount')) {
			amount = $(this).val();
			if ((amount > 0) && (account > 0)) {
				xml += '<' + type + ' account="' + account + '" amount="' + amount + '"/>'
				if (type == 'debit') {
					debits += Number(amount);
				}
				else if (type == 'credit') {
					credits += Number(amount);
				}
			}
		}
	});
	if (xml) {
		xml += '</journal>';
	}

	/* quick check to ensure debits - credits = 0 */
	if ((debits != credits) || (debits + credits == 0)) {
		$('p.journalstatus').text("Transaction is unbalanced");
		xml = false;
	}

	return xml;
}

function submitJournalEntry() {
	xml = validateJournalEntry();
	if (!xml) {
		return;
	}

	showSpinner();
    $.ajax({
        url: '/test/journal/',
        type: 'POST',
        data: xml,
        contentType: 'text/xml',
        success: function(xml) { submitJournalEntrySuccess(xml); },
        error: function(xml) { submitJournalEntryError(xml); },
    });
}

function submitJournalEntrySuccess(xml) {
	$('p.journalstatus').text("Journal posted");
	hideSpinner();
}

function submitJournalEntryError(xml) {
	$('p.journalstatus').text("Error posting journal");
	hideSpinner();
}

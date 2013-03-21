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
var g_password = '';
var g_instance = '';
var g_username = 'betty';    /* temp */
var g_password = 'ie5a8P40'; /* temp */
var g_instance = 'bacs';	 /* temp */
var g_business = '1';
var g_loggedin = false;
var g_max_ledgers_per_journal=3;
var g_frmLedger;
var g_tabid = 0;

$(document).ready(function() {

	/* no password, display login dialog */
	if (g_password == '') { displayLoginBox(); }

	/* prepare tabbed workarea */
	deployTabs();

	/* prepare menu */
	prepMenu();

	/* reload when logo clicked */
	$("img#logo").click(function(event) {
		event.preventDefault();
		$(this).fadeTo("slow", 0, function(){location.reload(true);});
	});     

	/* set up login box */
	$("form.signin :input").bind("keydown", function(event) {
		// handle enter key presses in input boxes
		var keycode = (event.keyCode ? event.keyCode :
			(event.which ? event.which : event.charCode));
		if (keycode == 13) { // enter key pressed
			// submit form
			document.getElementById('btnLogin').click();
			event.preventDefault();
		}
	});

	/* logout menu */
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
		url: g_authurl + g_username,
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
	$('.tabcloser').click(function(event) {
		event.preventDefault();
		closeTab($(this).attr('href'));
	});
}

/* add a new tab with content, optionally activating it */
function addTab(title, content, activate) {
	var tabid = g_tabid++;

	/* add tab and closer */
	$('ul.tablist').append('<li id="tabli' + tabid
		+ '" class="tabhead tablet' + tabid + ' business' + g_business + '">'
		+ '<a href="' + tabid + '">' + title + '</a>'
		+ '<a id="tabcloser' + tabid + '" class="tabcloser" href="'
		+ tabid  + '">'
		+ 'X</a></li>');

	/* add content */
	$('div.tabcontent').append('<div id="tab' + tabid + '" class="tablet '
		+ 'tablet' + tabid + ' business' + g_business + '">');
	$('div#tab' + tabid).append(content);

	/* add closer event */
    $('#tabcloser' + tabid).click(function(event) {
		event.preventDefault();
		closeTab(tabid);
	});

	/* set up tab navigation */
	$(".tablist li").click(function(event) {
		event.preventDefault();
		var selected_tab = $(this).find("a").attr("href");
		activateTab(selected_tab);
	});
	
	/* activate our new tab */
	if (activate) {
		activateTab(tabid);
	}

	/* fade in if we aren't already visible */
	$('div.tabs').fadeIn(300);
}

function activateTab(tabid) {
		console.log("activating tab " + tabid);
        /* remove "active" styling from all tabs for this business */
        $(".tabhead.business" + g_business).removeClass('active');
        $(".tablet.business" + g_business).removeClass('active');

        /* mark selected tab as active */
        $(".tablet" + tabid).addClass("active");

		/* set focus to control with class "focus" */
        $(".tablet" + tabid).find(".focus").focus();
}

/* 
 * Activate the "next" tab.
 *
 * Which tab is next?  Users have come to expect that if they close 
 * the active tab, the next tab to the right will become active,
 * unless there isn't one, in which case we go left instead.
 * See Mozilla Firefox tabs for an example.
 */
function activateNextTab(tabid) {
	var trytab = tabid + 1;

	console.log("Looking for a tab to activate...");
	/* Try right first */
	while (trytab < g_tabid) {
		console.log("Trying tab " + trytab);
		if ($('.tablet' + trytab).length != 0) {
			if ($('.tablet' + trytab).hasClass('business' + g_business)) {
				activateTab(trytab);
				return true;
			}
		}
		trytab++;
	}
	/* now go left */
	trytab = tabid - 1;
	while (trytab >= 0) {
		console.log("Trying tab " + trytab);
		if ($('.tablet' + trytab).length != 0) {
			if ($('.tablet' + trytab).hasClass('business' + g_business)) {
				activateTab(trytab);
				return true;
			}
		}
		trytab--;
	}
	return false; /* no tab to activate */
}

/* remove a tab */
function closeTab(tabid) {
	var tabcount = $('div#tabs').find('div').size();

	/* if tab is active, activate another */
	if ($('.tablet' + tabid).hasClass('active')) {
		console.log("tab (" + tabid  + ") was active");
		activateNextTab(tabid);
	}

	/* remove tab and content - call me in the morning if pain persists */
	$('.tablet' + tabid).remove();

	/* if we have tabs left, fade out */
	if (tabcount == 1) {
		$('div#tabs').fadeOut(300);
	}
}

/* Remove all tabs from working area */
function removeAllTabs() {
	$('ul.tablist').children().remove(); /* tab headers */
	$('div.tablet').fadeOut(300);		 /* content */
}

/* Add Authentication header with logged-in user's credentials */
function setAuthHeader(xhr) {
	var hash = auth_encode(g_username, g_password);
	xhr.setRequestHeader("Authorization", "Silent " + hash);
}

/* login successful, do successful things */
function loginok(xml) {
	g_instance = '';
	$(xml).find('instance').each(function() {
		g_loggedin = true;
		g_instance = $(this).text();
		console.log('Instance selected: ' + g_instance);
	});
	if (g_instance == '') {
		/* couldn't find instance for user - treat as failed login */
		loginfailed();
	}
	else {
		/* have instance, hide login dialog and get list of businesses */
		hideLoginBox();
		prepBusinessSelector();
	}
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

	/* clear business selector */
	select = $('select.businessselect');
	select.empty();
	select.append('<option>&lt;select business&gt;</option>');

	/* clear working area */
	removeAllTabs();

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

/* Set Focus in Login Dialog Appropriately */
function setFocusLoginBox() {
	// if username is blank, set focus there, otherwise set it to password
	if (g_username == '') {
		$("#username").focus();
	} else {
		$("#password").focus();
	}
};

/* Hide Login Dialog */
function hideLoginBox() {
	$('#mask , .login-popup').fadeOut(300 , function() {
		$('#mask').remove();  
	}); 
}

/* prepare static menus */
function prepMenu() {
	$('ul.nav').find('a').each(function() {
		console.log("Menu: " + $(this).text());
		$(this).click(clickMenu);
	});
}

/* Fetch user specific menus in xml format */
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

	console.log("Menu '" + $(this).text() + "' was clicked");

	if ($(this).attr("href") == '#journal') {
		setupJournalForm();
	} 
	else if ($(this).attr("href") == '#ledger') {
		showQuery('ledgers', 'General Ledger', true);
	} 
	else if ($(this).attr("href") == '#businessview') {
		showQuery('businesses', 'Businesses', true);
	}
	else if ($(this).attr("href") == '#business.create') {
		getForm('business', 'create', 'Add New Business');
	}
	else if ($(this).attr("href") == '#chartview') {
		showQuery('accounts', 'Chart of Accounts', true);
	}
	else if ($(this).attr("href") == '#chartadd') {
		showChartAddForm();
	}
	else if ($(this).attr("href") == '#contacts') {
		showQuery('contactlist', 'Contacts', true);
	}
	else if ($(this).attr("href") == '#contact.create') {
		getForm('contact', 'create', 'Add New Contact');
	}
	else if ($(this).attr("href") == '#departments.create') {
		getForm('department', 'create', 'Add New Department');
	}
	else if ($(this).attr("href") == '#divisions.create') {
		getForm('division', 'create', 'Add New Division');
	}
	else if ($(this).attr("href") == '#departments.view') {
		showQuery('departments', 'Departments', true);
	}
	else if ($(this).attr("href") == '#divisions.view') {
		showQuery('divisions', 'Divisions', true);
	}
	else if ($(this).attr("href") == '#organisations') {
		showQuery('organisations', 'Organisations', true);
	}
	else if ($(this).attr("href") == '#organisation.create') {
		getForm('organisation', 'create', 'Add New Organisation');
	}
	else if ($(this).attr("href") == '#rpt_balancesheet') {
		showQuery('reports/balancesheet', 'Balance Sheet', false);
	}
	else if ($(this).attr("href") == '#rpt_profitandloss') {
		showQuery('reports/profitandloss', 'Profit and Loss', false);
	}
	else if ($(this).attr("href") == '#help') {
		addTab("Help", "<h2>Help</h2>", true);
	}
	else if ($(this).attr("href") == '#') {
		// do nothing
		console.log('Doing nothing, successfully');
	}
	else {
		addTab("Not Implemented", "<h2>Feature Not Available Yet</h2>", true);
	}
}

/* Display query results as list */
function showQuery(collection, title, sort) {
	showSpinner();
	$.ajax({
		url: collection_url(collection),
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) {
			displayResultsGeneric(xml, title, sort);
		},
		error: function(xml) {
			displayResultsGeneric(xml, title);
		}
	});
}

/* fetch html form from server to display */
function getForm(object, action, title, xml) {
	$.ajax({
		url: '/html/forms/' + object + '/' + action + '.html',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(html) {
			displayForm(object, action, title, html, xml);
		},
		error: function(html) {
			displayForm(object, action, title, html);
		}
	});
}

/* display html form we've just fetched in new tab */
function displayForm(object, action, title, html, xml) {
	var id = 0;
	var content = '';
	var locString = '';

	$(html).find('div.' + object + '.action').each(function() {
		content += $(self).html();
	});


	addTab(title, html, true);

	if (xml) {
		/* we have some data, pre-populate form */
		$(xml).find('resources').find('row').children().each(function() {
			if (this.tagName == 'id') {
				id = $(this).text();
			}
			$("div.tablet.active").find('form.' + object).find(
				"[name='" + this.tagName + "']"
			).val($(this).text());

			if ((this.tagName == 'town') || (this.tagName == 'postcode')) {
				/* grab whatever location data we can, giving preference to 
				 * postcode */
				if ($(this).text().length > 0) {
					locString = $(this).text();
				}
			}

		});

		/* load map */
		if (locString.length > 0) {
			console.log('locString:' + locString);
			loadMap(locString);
		}
	}
	
	/* deal with subforms */
	$(html).find('form.subform').each(function() {
		var view = $(this).attr("action");
		var datatable = $('div.' + view).find('table.datatable');
		datatable.find('button.addrow').click(function(){
			addSubformEvent($(this), view, id);
		});
		loadSubformData(view, id);
	});

	hideSpinner(); /* wake user */

	$("div.tablet.active").find('form').submit(function(event) {
		event.preventDefault();
		if (id > 0) {
			submitForm(object, action, id);
		}
		else {
			submitForm(object, action);
		}
	});
}

/* Fetch data for a subform */
function loadSubformData(view, id) {
		console.log('Loading subform with data ' + view);
		url = collection_url(view);
		if (id) {
			url += id + '/';
		}
		$.ajax({
			url: url,
			beforeSend: function (xhr) { setAuthHeader(xhr); },
			success: function(xml) {
				console.log("Loaded subform data.  Hoorah.");
				displaySubformData(view, id, xml);
			},
			error: function(xml) {
				console.log('Error loading subform data');
			}
		});
}

function addSubformEvent(object, view, parentid) {
	/* attach click event to add rows to subform */
	console.log('Adding row to subform parent ' + parentid);

	/* the part before the underscore is the parent collection */
	var parent_collection = view.split('_')[0];
	var subform_collection = view.split('_')[1];

	var url = collection_url(subform_collection);
	var xml = createRequestXml();

	/* open xml element for the subform object */
	xml += '<' + subform_collection.slice(0,-1) + '>';

	/* find inputs */
	object.parent().parent().find('input').each(function() {
		xml += '<' + $(this).attr('name') + '>';
		xml += escapeHTML($(this).val());
		xml += '</' + $(this).attr('name') + '>';
	});

	/* add element for parent */
	xml += '<' + parent_collection + ' id="' + parentid + '"/>';

	/* close subform object element */
	xml += '</' + subform_collection.slice(0,-1) + '>';

	xml += '</data></request>';

	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) {
			console.log('SUCCESS: added row to subform');
			loadSubformData(view, parentid);
		},
		error: function(xml) {
			console.log('ERROR adding row to subform');
		},
	});
}

/* We've loaded data for a subform; display it */
function displaySubformData(view, parentid, xml) {
	var i = 0;
	var id = 0;
	console.log("Displaying subform " + view + " data");
	var datatable = $('div.' + view).find('table.datatable');
	var row = '';
	datatable.find('tbody').empty();

	$(xml).find('resources').find('row').each(function() {
		if (i % 2 == 0) {
			row = '<tr class="even">';
		} else {
			row = '<tr class="odd">';
		}

		$(this).children().each(function() {
			if (this.tagName == 'id') {
				id = $(this).text();
			}
			else {
				row += '<td>' + $(this).text() + '</td>';
			}
		});

		/* append remove "X" button */
		row += '<td class="removerow">';
		row += '<input type="hidden" name="id" value="' + id + '"/>';
		row += '<button class="removerow">X</button></td>';

		row += '</tr>';

		var newrow = $(row);

		/* attach click event to edit elements of subform */
		newrow.find('td:not(.removerow)').click(function() {
			var id = $(this).parent().find('input[name="id"]').val();
			collection = view.split('_')[1];
			displayElement(collection, id);
		});

		newrow.appendTo(datatable);
		i++;
	});
	datatable.find('tbody').fadeIn(300);

	/* clear form */
	datatable.find('input[type=text]').each(function() {
		$(this).val('');
	});
	datatable.find('input[type=email]').each(function() {
		$(this).val('');
	});

	/* attach click event to remove rows from subform */
	datatable.find('button.removerow').click(function() {
		var trow = $(this).parent();
		var id = trow.find('input[name="id"]').val();
		console.log('Delete sub id + ' + id + ' from parent ' + parentid);
		var url = collection_url(view) + parentid + '/' + id + '/';
		console.log('DELETE ' + url);
		$.ajax({
			url: url,
			type: 'DELETE',
			beforeSend: function (xhr) { setAuthHeader(xhr); },
			complete: function(xml) {
				trow.parent().remove();
				loadSubformData(view, parentid);
			},
		});

	});

	console.log('Found ' + i + ' row(s)');
}

/* build xml and submit form */
function submitForm(object, action, id) {
	var xml = createRequestXml();
	var url = '';

	console.log('Submitting form ' + object + ':' + action);

	/* find out where to send this */
	$("div.tablet.active").find(
		'div.' + object + '.' + action
	).find('form').each(function() {
		url = collection_url($(this).attr('action'));
		if (id) {
			url += id;
		}
	});

	/* build xml request */
	xml += '<' + object 
	if (id > 0) {
		xml += ' id="' + id + '"';
	}
	xml += '>';
	$("div.tablet.active").find(
		'div.' + object + '.' + action
	).find('input').each(function() {
		if ($(this).attr('name') != 'id') {
			xml += '<' + $(this).attr('name') + '>';
			xml += escapeHTML($(this).val());
			xml += '</' + $(this).attr('name') + '>';
		}
	});
	xml += '</' + object + '>';
	xml += '</data></request>';

	showSpinner(); /* tell user to wait */

	/* send request */
    $.ajax({
        url: url,
        type: 'POST',
        data: xml,
        contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) { submitFormSuccess(object, action, id); },
        error: function(xml) { submitFormError(object, action, id); },
    });
}

/* Replace HTML Special Characters */
function escapeHTML(html) {
	var x;
	var hchars = {
		'&': '&amp;',
		'<': '&lt;',
		'>': '&gt;',
		'"': '&quot;',
	};

	for (x in hchars) {
		html = html.replace(new RegExp(x, 'g'), hchars[x]);
	}

	return html;
}

function submitFormSuccess(object, action, id) {
	hideSpinner();
	if (object == 'business') {
		prepBusinessSelector();
	}
}

function submitFormError(object, action, id) {
	hideSpinner();
}

/* Fetch an individual element of a collection for display / editing */
function displayElement(collection, id) {
	if (collection.toLowerCase() == 'contacts') {
		url = collection_url('contacts') + id;
		object = 'contact';
		action = 'update';
		title = 'Edit Contact ' + id;
	}
	else if (collection.toLowerCase() == 'organisations') {
		url = collection_url('organisations') + id;
		object = 'organisation';
		action = 'update';
		title = 'Edit Organisation ' + id;
	}
	else {
		return;
	}

	showSpinner(); /* tell user to wait */

	/* first, fetch xml data */
	$.ajax({
		url: url,
		type: 'GET',
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { getForm(object, action, title, xml); },
		error: function(xml) { hideSpinner(); },
	});

}

/* display XML results as a sortable table */
function displayResultsGeneric(xml, title, sorted) {
	if ($(xml).find('resources').children().length == 0) {
		/* No results found */
		hideSpinner();
		if (title == 'Contacts') {
			getForm('contact', 'create', 'Add New Contact');
		}
		else if (title == 'Organisations') {
			getForm('organisation', 'create', 'Add New Organisation');
		}
		else {
			addTab(title, "<p>Nothing found</p>", true);
		}
		return;
	}

	$t = '<table class="datatable">';
	$t += "<thead>";
	$t += "<tr>";
	var row = 0;
	$(xml).find('resources').children().each(function() {
		row += 1;
		if (row == 1) {
			$(this).children().each(function() {
				$t += '<th class="xml-' + this.tagName + '">';
				$t += this.tagName + '  </th>';
			});
			$t += "</tr>";
			$t += "</thead>";
			$t += "<tbody>";
		}
		if (row % 2 == 0) {
			$t += '<tr class="even ' + this.tagName  + '">';
		} else {
			$t += '<tr class="odd ' + this.tagName  + '">';
		}
		$(this).children().each(function() {
			$t += '<td class="xml-' + this.tagName + '">' + $(this).text()
			/* if this is a numeric value, and positive, add trailing space */
			if ((this.tagName == 'debit') || (this.tagName == 'credit') 
			 || (this.tagName == 'total') || (this.tagName == 'amount'))
			{
				if ($(this).text().substr(-1) != ')') {
					$t += ' ';
				}
			}
			$t += '</td>';
		});
		$t += "</tr>";
	});
	$t += "</tbody>";
	$t += "</table>";

	if (! title) {
		title = "Results";
	}

	$t = $($t); /* htmlify */

	/* attach click event */
	$t.find('tr').click(function(event) {
		event.preventDefault();
		displayElement(title,$(this).find('td.xml-id').text());
	});

	addTab(title, $t, true);

	/* make our table pretty and sortable */
	if (sorted) {
		$('.tablet.active.business' + g_business).find(".datatable").tablesorter({
			sortList: [[0,0], [1,0]], 
			widgets: ['zebra'] 
		});
	}

	hideSpinner();
}

/* hide please wait dialog */
function showSpinner() {
	$("#loading-div-background").show();
}

/* hide please wait dialog */
function hideSpinner() {
	$("#loading-div-background").hide();
}

/* Populate Accounts Drop-Downs with XML Data */
function populateAccountsDDowns(xml, tab) {
	$('select.account').empty();
	$('select.account').append(
		$("<option />").val(0).text('<select account>')
	);
	$(xml).find('row').each(function() {
		var accountid = $(this).find('nominalcode').text();
		var accounttype = $(this).find('type').text();
		var accountdesc = accountid + " - " +
		$(this).find('account').text();

		$('select.account').append(
			$("<option />").val(accountid).text(accountdesc)
		);
	});

	finishJournalForm(tab);
}

function populateDepartmentsDDowns(xml, tab) {
	$('select.department').empty();
	$(xml).find('row').each(function() {
		var id = $(this).find('id').text();
		var name = $(this).find('name').text();
		$('select.department').append(
			$("<option />").val(id).text(name)
		);
	});
}

function populateDivisionsDDowns(xml, tab) {
	$('select.division').empty();
	$(xml).find('row').each(function() {
		var id = $(this).find('id').text();
		var name = $(this).find('name').text();
		$('select.division').append(
			$("<option />").val(id).text(name)
		);
	});
}

/* debits and credits */
function populateDebitCreditDDowns() {
	$('select.type:not(.populated)').empty();
	$('select.type:not(.populated)').append(
		$("<option />").val('debit').text('debit')
	);
	$('select.type:not(.populated)').append(
		$("<option />").val('credit').text('credit')
	);
	$('select.type:not(.populated)').addClass('populated');
}

/* return url for collection */
function collection_url(collection) {
	var url;
	url =  '/' + g_instance + '/' + g_business + '/' + collection + '/';
	return url;
}

/* set up journal form */
function setupJournalForm(tab) {

	/* load dropdown contents */
	$.ajax({
		url: collection_url('divisions'),
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function (xml) {
			populateDivisionsDDowns(xml, tab);
		}
	});

	$.ajax({
		url: collection_url('departments'),
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function (xml) {
			populateDepartmentsDDowns(xml, tab);
		}
	});

	$.ajax({
		url: collection_url('accounts'),
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function (xml) {
			populateAccountsDDowns(xml, tab);
		}
	});

	populateDebitCreditDDowns();
}

/* show the form, after setup is complete */
function finishJournalForm(tab) {
	var ledger_lines = 1;
	var jf = $('div.dataformdiv.template').clone();
	jf.removeClass('template');
	if (tab) {
		/* clear existing tab */
		tab.empty();
		tab.append(jf);
	}
	else {
		/* clone template into new tab */
		addTab('Journal Entry', jf, true);
	}

	/* add some ledger lines */
	var jl = jf.find('fieldset.ledger').clone();
	while (ledger_lines < g_max_ledgers_per_journal) {
		jf.find('form').append(jl.clone());
		ledger_lines++;
	}

	/* add datepicker */
	var transactdate = jf.find('.transactdate');
	var currentDate = new Date();
	transactdate.val($.now());
	transactdate.datepicker({
		dateFormat: "yy-mm-dd",
		constrainInput: true
	});
	transactdate.datepicker("setDate",currentDate);

	/* set up click() events */
	$('button#journalsubmit').click(function(event) {
		submitJournalEntry(event, jf);
	});

	/* set up blur() events */
	$('div.tablet.active.business'
						+ g_business).find('input.amount').each(function() {
		$(this).blur(function() {
			/* pad amounts to two decimal places */
			var newamount = decimalPad($(this).val(), 2);
			if (newamount == '0.00') {
				/* blank out zeros */
				$(this).val('');
			}
			else {
				$(this).val(newamount);
			}
		});
	});

	/* display the form */
	jf.fadeIn(300);
	jf.find('p.journalstatus').fadeOut(5000);

	/* set focus */
	jf.find(".description").focus();

	/* set up input validation events */
	/* TODO */

}

/* validate journal entry form and return xml to submit */
function validateJournalEntry(form) {
	var xml = createRequestXml();
	var account;
	var division = 0;
	var department = 0;
	var type;
	var amount;
	var debits = 0;
	var credits = 0;
	var debitxml = '';
	var creditxml = '';

	$(form).find('p.journalstatus').text("");
	$(form).find('fieldset').children().each(function() {
		if ($(this).hasClass('description')) {
			/* ensure we have a description */
			if ($(this).val().trim().length == 0) {
				$(form).find('p.journalstatus').text(
					"A description is required"
				);
				$(form).find('p.journalstatus').fadeIn(300);
				xml = false;
				return false;
			}
			xml = createRequestXml();
			xml += '<journal ';
			xml += 'transactdate="' + $(form).find('.transactdate').val()
				+ '" ';
			xml += 'description="'+ escapeHTML($(this).val().trim()) +'">';
		}
		else if ($(this).hasClass('account')) {
			account = $(this).val();
		}
		else if ($(this).hasClass('division')) {
			division = $(this).val();
		}
		else if ($(this).hasClass('department')) {
			department = $(this).val();
		}
		else if ($(this).hasClass('type')) {
			type = $(this).val();
		}
		else if ($(this).hasClass('amount')) {
			amount = $(this).val();
			if ((amount > 0) && (account > 0)) {
				if (type == 'debit') {
					debits = decimalAdd(debits, amount);
					debitxml += '<' + type + ' account="' + account;
					debitxml += '" division="' + division;
					debitxml += '" department="' + department;
					debitxml += '" amount="' + amount + '"/>';
				}
				else if (type == 'credit') {
					credits = decimalAdd(credits, amount);
					creditxml += '<' + type + ' account="' + account;
					creditxml += '" division="' + division;
					creditxml += '" department="' + department;
					creditxml += '" amount="' + amount + '"/>';
				}
			}
		}
	});
	if (xml) {
		xml += debitxml;
		xml += creditxml;
		xml += '</journal></data></request>';
	}

	/* quick check to ensure debits - credits = 0 */
	console.log('debits=' + debits);
	console.log('credits=' + credits);
	if (!(decimalEqual(debits, credits))) {
		$(form).find('p.journalstatus').text("Transaction is unbalanced");
		$(form).find('p.journalstatus').fadeIn(300);
		xml = false;
	}
	if (decimalEqual(decimalAdd(debits, credits), 0)) {
		$(form).find('p.journalstatus').text("Transaction is zero");
		$(form).find('p.journalstatus').fadeIn(300);
		xml = false;
	}

	return xml;
}

/* Javascript has no decimal type, so we need to teach it how to add up */
function decimalAdd(x, y) {
	var xplaces = 0;
	var yplaces = 0;

	/* first, check we have only one decimal point, if any, */
	/* and make a note of how many decimal places each term has */	
	var dpx = String(x).match(/\./g);
	if (dpx) {
		points = dpx.length;
		if ((points != 0) && (points != 1)) {
			throw "First argument to decimalAdd() is not a decimal";
		}
		xplaces = String(x).length - String(x).indexOf('.') - 1;
	}
	var dpy = String(y).match(/\./g);
	if (dpy) {
		points = dpy.length;
		if ((points != 0) && (points != 1)) {
			throw "Second argument to decimalAdd() is not a decimal";
		}
		yplaces = String(y).length - String(y).indexOf('.') - 1;
	}

	/* make number of decimal places even by adding zeros to the end */
	if (xplaces < yplaces) {
		if (xplaces == 0) {
			xplaces = 1; /* leave space for decimal point */
		}
		x = String(x) + '0' * (yplaces - xplaces);
		xplaces = yplaces;
	}
	if (yplaces < xplaces) {
		if (yplaces == 0) {
			yplaces = 1; /* leave space for decimal point */
		}
		y = String(y) + '0' * (xplaces - yplaces);
		yplaces = xplaces;
	}

	/* remove the decimal point from the string */
	x = String(x).replace('.', '');
	y = String(y).replace('.', '');

	/* add two integers - even javascript can manage that */
	sum = Number(x) + Number(y);

	if (xplaces > 0) {
		/* put back the decimal point in the correct position */
		sum = String(sum).substring(0,String(sum).length-xplaces) + '.'
			+ String(sum).substring(String(sum).length-xplaces);
	}

	return String(sum);
}

/* Compare two string representations of decimals numerically */
function decimalEqual(term1, term2) {
	return (Number(term1) == Number(term2));
}

/* Return string representation of decimal padded to at least <digits> 
 * decimal places */
function decimalPad(decimal, digits) {
	/* if decimal is blank, or NaN, make it zero */
	if ((isNaN(decimal)) || (decimal == '')) {
		decimal = '0';
	}

	/* first, convert to a number and back to a string - this strips any 
	 * useless leading and trailing zeros. We'll put back the ones we need. */
	decimal = String(Number(decimal));

	var point = String(decimal).match(/\./g);

	if (point) {
		pindex = String(decimal).indexOf('.');
		places = String(decimal).length - pindex - 1;
		console.log(decimal + ' has ' + places + ' places');
		if (places < digits) {
			decimal = String(decimal) + '0' * (digits - places);
		}
	}
	else {
		decimal = String(decimal) + '.00';
	}
	return decimal;
}

function submitJournalEntry(event, form) {
	event.preventDefault();
	xml = validateJournalEntry(form);
	if (!xml) {
		return;
	}

	showSpinner();
    $.ajax({
		url: collection_url('journals'),
        type: 'POST',
		data: xml,
        contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) { submitJournalEntrySuccess(xml); },
        error: function(xml) { submitJournalEntryError(xml); },
    });
}

/* journal was posted successfully */
function submitJournalEntrySuccess(xml) {
	$('p.journalstatus').text("Journal posted");
	$('p.journalstatus').fadeIn(300);
	var activeForm = $('.tablet.active');
	setupJournalForm(activeForm);
	hideSpinner();
}

/* problem posting journal */
function submitJournalEntryError(xml) {
	$('p.journalstatus').text("Error posting journal");
	$('p.journalstatus').fadeIn(300);
	hideSpinner();
}

/* display form to add new chart accounts */
function showChartAddForm(tab) {
	form = '<div class="dataformdiv">';
	form += '<h2 class="formtitle">Add Chart Account</h2>';
	form += '<form class="chartadd">';
	form += '<input class="description" type="text" ';
	form += 'placeholder="Chart Description"/>';
	form += '<button class="submit">Save</button>';
	form += '<button class="cancel">Cancel</button>';
	form += '</form>';
	form += '</div>';

	newform = $(form);
	
	addTab("Add Chart Account", newform, true);

	$('form.chartadd').find('button.submit').click(function(event) {
		submitChartAdd(event, newform);
	});

    /* load dropdown contents */
    $.ajax({
		url: collection_url('accounttypes'),
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function (xml) {
            populateAccountTypeDDowns(xml, newform);
        }
    });
}

function populateAccountTypeDDowns(xml, form) {
	select = $('<select class="accounttype"></select>');
	select.append($("<option />").val(0).text('<select account type>'));

	$(xml).find('row').each(function() {
		var id = $(this).find('id').text();
		var name = $(this).find('name').text();
		select.append($("<option />").val(id).text(name));
	});

	form.find('form.chartadd').prepend(select);
	form.fadeIn(300);

}

function validateChartAdd(form) {
	var xml = createRequestXml();
    xml += '<account type="';
	xml += $(form).find('select.accounttype').val();
    xml += '" description="';
	xml += escapeHTML($(form).find('input.description').val());
    xml += '"/></data></request>';

	return xml;
}

function submitChartAdd(event, form) {
	event.preventDefault();
	xml = validateChartAdd(form);
	if (!xml) {
		return;
	}

	showSpinner();
    $.ajax({
		url: collection_url('accounts'),
        type: 'POST',
        data: xml,
        contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) { hideSpinner(); },
        error: function(xml) { hideSpinner(); },
    });
}

/* Start building an xml request */
function createRequestXml() {
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request>';
	xml += '<instance>' + g_instance + '</instance>';
	xml += '<business>' + g_business + '</business>';
	xml += '<data>';
	return xml;
}

/* create business selector combo */
function prepBusinessSelector() {
	$.ajax({
		url: collection_url('businesses'),
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) {
			showBusinessSelector(xml);
		},
		error: function(xml) {
			getForm('business', 'create', 'Add New Business');
		}
	});
}

/* Display combo for switching between businesses */
function showBusinessSelector(xml) {
	if ($(xml).find('row').length == 0) {
		/* No businesses found */
		getForm('business', 'create', 'Add New Business');
		return;
	}

	select = $('select.businessselect');
	select.empty();

	$(xml).find('row').each(function() {
		var id = $(this).find('id').text();
		var name = $(this).find('name').text();
		select.append($("<option />").val(id).text(name));
	});
	
	select.change(function() {
		switchBusiness($(this).val());
	});

	$('select.businessselect').val(g_business);
}

/* Switch to the selected business */
function switchBusiness(business) {
	/* hide content of active tab */
	$('.tablet.active').addClass('hidden');

	/* hide all tabheads for this business */
	$('.tabhead.business' + g_business).each(function() {
		$(this).addClass('hidden');
	});

	/* switch business */
	g_business = business;

	/* unhide tabs for new business */
	$('.tabhead.business' + g_business).each(function() {
		$(this).removeClass('hidden');
	});
	$('.tablet.business' + g_business).each(function() {
		$(this).removeClass('hidden');
	});
}

function loadMap(locationString) {
	var canvas;
	var map;
	var geocoder = new google.maps.Geocoder();

	var mapOptions = {
	    zoom: 15,
		mapTypeId: google.maps.MapTypeId.ROADMAP
	}

	var activeTablet = $('.tablet.active.business' + g_business);
	activeTablet.find('.map-canvas').each(function() {
		console.log('found a map-canvas');
		canvas = this;
		$(canvas).fadeIn(300);
		map = new google.maps.Map(canvas, mapOptions);
	});

	if (!(map)) {
		console.log('No map-canvas found');
		return;
	}

	geocoder.geocode( { 'address': locationString}, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			map.setCenter(results[0].geometry.location);
			var marker = new google.maps.Marker({
				map: map,
				position: results[0].geometry.location
			});
		} else {
			console.log("Geocode was not successful for the following reason: "
				+ status);
		}
	});

}

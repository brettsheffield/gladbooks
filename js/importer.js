/* 
 * importer.js - gladbooks data import functions
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

$(document).ready(function() {
	console.log('Gladbooks Data Importer loaded.');
});

function clickMenu(event) {
	event.preventDefault();

	if ($(this).attr("href") == '#import_gladserv') {
		console.log('Importing Gladserv Ltd data...');
		importData('gladserv');
	}
	else if ($(this).attr("href") == '#import_penguinfactory') {
		console.log('Importing Penguin Factory Ltd data...');
		importData('penguinfactory');
	}
	else if ($(this).attr("href") == '#') {
		console.log('Doing nothing, successfully');
	}
	else {
		addTab("Not Implemented", "<h2>Feature Not Available Yet</h2>", true);
	}
}

function importData(src) {
	console.log('importData()');
	var d = new Array();

	showSpinner(); /* tell user to wait */

	d.push(getXML('/' + src + '/organisations/'));

	$.when.apply(null, d)
	.done(function(xml) {
		console.log('data fetched');
		displayResultsGeneric(xml, 'organisations', 'Accounts', true);
		createOrganisations(xml);
	})
	.fail(function() {
		console.log('failed to fetch data');
		hideSpinner();
	});
}

/* override gladbooks.js function */
function displayElement() {
	// do nothing
}

function createOrganisations(xml) {
	var row = 0;
	$(xml).find('resources').find('row').each(function() {
		row += 1;
		var doc = '';
		var organisation_name = null;
		var organisation_isactive = null;
		var organisation_issuspended = null;
		var organisation_isvatreg = null;
		var organisation_terms = null;
		var organisation_vatnumber = null;

		$(this).children().each(function() {
			if (this.tagName == 'name') {
				organisation_name = $(this).text();
			}
			else if (this.tagName == 'is_active') {
				organisation_isactive = $(this).text();
			}
			else if (this.tagName == 'is_suspended') {
				organisation_issuspended = $(this).text();
			}
			else if (this.tagName == 'is_isvatreg') {
				organisation_isvatreg = $(this).text();
			}
			else if (this.tagName == 'term') {
				organisation_terms = $(this).text();
			}
			else if (this.tagName == 'vatnumber') {
				organisation_vatnumber = $(this).text();
			}
		});
		if (organisation_name != null) {
			doc += '<organisation';
			if (organisation_isactive != null) {
				doc += ' is_active="' + organisation_isactive + '"';
			}
			if (organisation_issuspended != null) {
				doc += ' is_suspended="' + organisation_issuspended + '"';
			}
			if (organisation_isvatreg != null) {
				doc += ' is_vatreg="' + organisation_isvatreg + '"';
			}
			doc += '>';
			doc += '<name>' + escapeHTML(organisation_name) + '</name>';
			if (organisation_terms != null) {
				doc += '<terms>' + organisation_terms + '</terms>';
			}
			if (organisation_vatnumber != null) {
				if (organisation_vatnumber != 'NULL') {
					doc += '<vatnumber>';
					doc += escapeHTML(organisation_vatnumber);
					doc += '</vatnumber>';
				}
			}
			doc += '</organisation>';
			postDoc(organisation_name, doc);
		}
	});
	console.log(row + ' row(s) processed');
}

function postDoc(name, doc) {
	var xml = createRequestXml() + doc + '</data></request>';
	d = $.ajax({
		url: collection_url('organisations'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { 
			console.log('organisation "' + name + '" created'); 
		},
	});
	return d;
}

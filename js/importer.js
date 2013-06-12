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
		createOrganisations(src, xml);
	})
	.fail(function() {
		console.log('failed to fetch data');
		hideSpinner();
	});
}

function fetchContactsByOrganisation(src, id) {
	var d = new Array();
	d.push(getXML('/' + src + '/organisation_contacts/' + id + '/'));
	return d;
}

/* override gladbooks.js function */
function displayElement() {
	// do nothing
}

function createOrganisations(src, xml) {
	var row = 0;

	/* loop through rows */
	$(xml).find('resources').find('row').each(function() {
		row += 1;
		var doc = '';
		var organisation_id = null;
		var organisation_name = null;
		var organisation_isactive = null;
		var organisation_issuspended = null;
		var organisation_isvatreg = null;
		var organisation_terms = null;
		var organisation_vatnumber = null;
		
		/* loop through fields */
		$(this).children().each(function() {
			if ((this.tagName == 'account')||(this.tagName == 'organisation')){
				organisation_id = $(this).text();
			}
			else if (this.tagName == 'name') {
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
		/* build organisation xml */
		if (organisation_name != null) {
			doc += '<organisation';
			doc = appendXMLAttr(doc, 'orgcode', organisation_id);
			doc = appendXMLAttr(doc, 'is_active', organisation_isactive);
			doc = appendXMLAttr(doc, 'is_suspended', organisation_issuspended);
			doc = appendXMLAttr(doc, 'is_vatreg', organisation_isvatreg);
			doc += '>';
			doc = appendXMLTag(doc, 'name', organisation_name);
			doc = appendXMLTag(doc, 'terms', organisation_terms);
			doc = appendXMLTag(doc, 'vatnumber', organisation_vatnumber);
			/* insert contacts here */
			d = fetchContactsByOrganisation(src, organisation_id);
			$.when.apply(null, d)
			.done(function(contacts) {
				doc = appendXMLContacts(doc, contacts);
				doc += '</organisation>';
				postDoc(organisation_name, doc);
			})
		}
	});
	console.log(row + ' row(s) processed');
}

function appendXMLAttr(doc, attribute, value) {
	if ((value != null) && (value != 'NULL')) {
		doc += ' ' + attribute + '="' + value + '"';
	}
	return doc;
}

function appendXMLTag(doc, tagName, value) {
	if ((value != null) && (value != 'NULL') && (value != 'None')){
		doc += '<' + tagName + '>' + escapeHTML(value) + '</' + tagName + '>';
	}
	return doc;
}

function appendXMLContacts(doc, xml) {
	$(xml).find('resources').find('row').each(function() {
		var contact_name = null;
		var contact_isbilling = null;
		var contact_isshipping = null;
		var contact_isactive = null;
		var contact_line1 = null;
		var contact_line2 = null;
		var contact_line3 = null;
		var contact_town = null
		var contact_county = null;
		var contact_country = null;
		var contact_postcode = null;
		var contact_email = null;
		var contact_phone = null;
		var contact_phonealt = null;
		var contact_mobile = null;
		var contact_fax = null;

		$(this).children().each(function() {
			if (this.tagName == 'name') {
				contact_name = $(this).text();
			}
			else if (this.tagName == 'is_billing') {
				contact_isbilling = $(this).text();
			}
			else if (this.tagName == 'is_shipping') {
				contact_isshipping = $(this).text();
			}
			else if (this.tagName == 'is_active') {
				contact_isactive = $(this).text();
			}
			else if (this.tagName == 'line_1') {
				contact_line1 = $(this).text();
			}
			else if (this.tagName == 'line_2') {
				contact_line2 = $(this).text();
			}
			else if (this.tagName == 'line_3') {
				contact_line3 = $(this).text();
			}
			else if (this.tagName == 'town') {
				contact_town = $(this).text();
			}
			else if (this.tagName == 'county') {
				contact_county = $(this).text();
			}
			else if (this.tagName == 'country') {
				contact_country = $(this).text();
			}
			else if (this.tagName == 'postcode') {
				contact_postcode = $(this).text();
			}
			else if (this.tagName == 'email') {
				contact_email = $(this).text();
			}
			else if (this.tagName == 'phone') {
				contact_phone = $(this).text();
			}
			else if (this.tagName == 'phonealt') {
				contact_phonealt = $(this).text();
			}
			else if (this.tagName == 'mobile') {
				contact_mobile = $(this).text();
			}
			else if (this.tagName == 'fax') {
				contact_fax = $(this).text();
			}
		});
		doc += '<contact';
		doc = appendXMLAttr(doc, 'is_active', contact_isactive);
		doc += '>';
		doc = appendXMLTag(doc, 'name', contact_name);
		doc = appendXMLTag(doc, 'line_1', contact_line1);
		doc = appendXMLTag(doc, 'line_2', contact_line2);
		doc = appendXMLTag(doc, 'line_3', contact_line3);
		doc = appendXMLTag(doc, 'town', contact_town);
		doc = appendXMLTag(doc, 'county', contact_county);
		doc = appendXMLTag(doc, 'country', contact_country);
		doc = appendXMLTag(doc, 'postcode', contact_postcode);
		doc = appendXMLTag(doc, 'email', contact_email);
		doc = appendXMLTag(doc, 'phone', contact_phone);
		doc = appendXMLTag(doc, 'phonealt', contact_phonealt);
		doc = appendXMLTag(doc, 'mobile', contact_mobile);
		doc = appendXMLTag(doc, 'fax', contact_fax);
		doc = appendXMLRelationship(doc, '1', contact_isbilling);
		doc = appendXMLRelationship(doc, '2', contact_isshipping);
		doc += '</contact>';
	});
	return doc;
}

function appendXMLRelationship(doc, type, value) {
	if (value == 1) {
		doc += '<relationship type="' + type + '"/>';
	}
	return doc;
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

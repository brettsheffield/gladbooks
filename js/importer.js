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
	d.push(getXML('/' + src + '/products/'));

	$.when.apply(null, d)
	.done(function(xml) {
		console.log('data fetched');
		var args = Array.prototype.splice.call(arguments, 1);
		displayResultsGeneric(xml, 'organisations', 'Accounts', true);
		//createOrganisations(src, xml[0]);
		var attributes = ['product'];
		var fields = ['account', 'nominalcode', 'shortname', 'description', 'price_buy', 'price_sell', 'price'];
		var fieldmap = {'product': 'import_id', 'nominalcode': 'account', 'price': 'price_sell'};
		createObjects('product', src, args[0], attributes, fields, fieldmap);
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

/* TODO: refactor to use createObjects() */
function createOrganisations(src, xml) {
	var row = 0;

	/* loop through rows */
	$(xml).find('resources').find('row').each(function() {
		row += 1;
		var doc = '';
		var organisation = new Object();
		
		/* loop through fields */
		$(this).children().each(function() {
			setTagValue(organisation, 'id', this, 'account');
			setTagValue(organisation, 'id', this, 'organisation');
			setTagValue(organisation, 'name', this, 'name');
			setTagValue(organisation, 'isactive', this, 'is_active');
			setTagValue(organisation, 'issuspended', this, 'is_suspended');
			setTagValue(organisation, 'isvatreg', this, 'is_isvatreg');
			setTagValue(organisation, 'terms', this, 'term');
			setTagValue(organisation, 'vatnumber', this, 'vatnumber');
		});
		/* build organisation xml */
		if (organisation.name != null) {
			doc += '<organisation';
			doc = appendXMLAttr(doc, 'orgcode', organisation.id);
			doc = appendXMLAttr(doc, 'is_active', organisation.isactive);
			doc = appendXMLAttr(doc, 'is_suspended', organisation.issuspended);
			doc = appendXMLAttr(doc, 'is_vatreg', organisation.isvatreg);
			doc += '>';
			doc = appendXMLTag(doc, 'name', organisation.name);
			doc = appendXMLTag(doc, 'terms', organisation.terms);
			doc = appendXMLTag(doc, 'vatnumber', organisation.vatnumber);
			/* insert contacts here */
			d = fetchContactsByOrganisation(src, organisation.id);
			$.when.apply(null, d)
			.done(function(contacts) {
				doc = appendXMLContacts(doc, contacts);
				doc += '</organisation>';
				postDoc('organisation', organisation.name, doc);
			})
		}
	});
	console.log(row + ' row(s) processed');
}

function createObjects(object, src, xml, attributes, fields, fieldmap) {
	var row = 0;

	/* loop through rows */
	$(xml).find('resources').find('row').each(function() {
		row += 1;
		var doc = '';
		var obj = new Object();

		/* loop through fields */
		$(this).children().each(function() {
			for (i=0; i< attributes.concat(fields).length; i++) {
				var fld = attributes.concat(fields)[i];
				if ((fields.indexOf(this.tagName) != -1) ||
				    (attributes.indexOf(this.tagName) != -1)) 
				{
					/* this is a field we want to import */
					if (this.tagName in fieldmap) {
						/* map this field to a different field name */
						obj[fieldmap[this.tagName]] = $(this).text();
					}
					else {
						/* use field name unmapped */
						obj[this.tagName] = $(this).text();
					}
				}
			}
		});
		/* build xml */
		if (obj.shortname != null) {
			doc += '<' + object;
			for (i=0; i<attributes.length; i++) {
				if (fieldmap[attributes[i]]) {
					doc = appendXMLAttr(doc, fieldmap[attributes[i]], obj[attributes[i]]);
				}
				else {
					doc = appendXMLAttr(doc, attributes[i], obj[attributes[i]]);
				}
			}
			doc += '>';
			for (i=0; i<fields.length; i++) {
				if (fieldmap[fields[i]]) {
					doc = appendXMLTag(doc, fieldmap[fields[i]], obj[fields[i]]);
				}
				else {
					doc = appendXMLTag(doc, fields[i], obj[fields[i]]);
				}
			}
			doc += '</' + object + '>';
		}
		postDoc(object, doc);
	});
	console.log(row + ' row(s) processed');
}

function setTagValue(object, attr, tag, tagName) {
	if (tag.tagName == tagName) {
		object[attr] = $(tag).text();
	}
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
		doc = appendXMLRelationship(doc, '0', '1');
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

function postDoc(object, doc) {
	var xml = createRequestXml() + doc + '</data></request>';
	d = $.ajax({
		url: collection_url(object + 's'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { 
			console.log(object + ' created'); 
		},
	});
	return d;
}

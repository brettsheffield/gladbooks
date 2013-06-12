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

		/* import organisations & contacts */
		var attributes = ['account', 'organisation', 'is_active', 'is_suspended', 'is_vatreg'];
		var fields = ['name', 'terms', 'vatnumber'];
		var fieldmap = {'account':'orgcode', 'organisation':'orgcode'};
		createObjects('organisation', src, xml[0], attributes, fields, fieldmap);

		/* import products */
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
		doc += '<' + object;
		/* attributes */
		for (i=0; i<attributes.length; i++) {
			if (fieldmap[attributes[i]]) {
				doc = appendXMLAttr(doc, fieldmap[attributes[i]], obj[attributes[i]]);
			}
			else {
				doc = appendXMLAttr(doc, attributes[i], obj[attributes[i]]);
			}
		}
		doc += '>';
		/* fields */
		for (i=0; i<fields.length; i++) {
			if (fieldmap[fields[i]]) {
				doc = appendXMLTag(doc, fieldmap[fields[i]], obj[fields[i]]);
			}
			else {
				doc = appendXMLTag(doc, fields[i], obj[fields[i]]);
			}
		}
		if (object == 'organisation') {
			/* for organisation we need to import contacts also */
			d = fetchContactsByOrganisation(src, obj["orgcode"]);
			$.when.apply(null, d)
			.done(function(contacts) {
				doc = appendXMLContacts(doc, contacts);
				doc += '</' + object + '>';
				postDoc(object, doc);
			})
			.fail(function() {
				doc += '</' + object + '>';
				postDoc(object, doc);
			});
		}
		else {
			doc += '</' + object + '>';
			postDoc(object, doc);
		}
	});
	console.log(row + ' row(s) processed');
}

function setTagValue(object, attr, tag) {
	if (tag.tagName == attr) {
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
	var object = 'contact';
	$(xml).find('resources').find('row').each(function() {
		var contact = new Object();

		$(this).children().each(function() {
			setTagValue(contact, 'name', this);
			setTagValue(contact, 'is_billing', this);
			setTagValue(contact, 'is_shipping', this);
			setTagValue(contact, 'is_active', this);
			setTagValue(contact, 'line_1', this);
			setTagValue(contact, 'line_2', this);
			setTagValue(contact, 'line_3', this);
			setTagValue(contact, 'town', this);
			setTagValue(contact, 'county', this);
			setTagValue(contact, 'country', this);
			setTagValue(contact, 'postcode', this);
			setTagValue(contact, 'email', this);
			setTagValue(contact, 'phone', this);
			setTagValue(contact, 'phonealt', this);
			setTagValue(contact, 'mobile', this);
			setTagValue(contact, 'fax', this);
		});
		doc += '<' + object;
		doc = appendXMLAttr(doc, 'is_active', contact.is_active);
		doc += '>';
		doc = appendXMLTag(doc, 'name', contact.name);
		doc = appendXMLTag(doc, 'line_1', contact.line_1);
		doc = appendXMLTag(doc, 'line_2', contact.line_2);
		doc = appendXMLTag(doc, 'line_3', contact.line_3);
		doc = appendXMLTag(doc, 'town', contact.town);
		doc = appendXMLTag(doc, 'county', contact.county);
		doc = appendXMLTag(doc, 'country', contact.country);
		doc = appendXMLTag(doc, 'postcode', contact.postcode);
		doc = appendXMLTag(doc, 'email', contact.email);
		doc = appendXMLTag(doc, 'phone', contact.phone);
		doc = appendXMLTag(doc, 'phonealt', contact.phonealt);
		doc = appendXMLTag(doc, 'mobile', contact.mobile);
		doc = appendXMLTag(doc, 'fax', contact.fax);
		doc = appendXMLRelationship(doc, '0', '1');
		doc = appendXMLRelationship(doc, '1', contact.is_billing);
		doc = appendXMLRelationship(doc, '2', contact.is_shipping);
		doc += '</' + object + '>';
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

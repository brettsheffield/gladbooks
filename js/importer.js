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
	showSpinner(); /* tell user to wait */

	var d = fetchData(src);
	$.when.apply(null, d)
	.done(function(xml) {
		hideSpinner();
		var args = Array.prototype.splice.call(arguments, 0);
		processData(src, args);
	})
	.fail(function() {
		console.log('failed to fetch data');
		hideSpinner();
	});
}

function ImportSchema() {
}

function fetchRelatedData(schema, id) {
	var d = new Array();
	for (i=0; i<schema.children.length; i++) {
		d.push(getXML('/' + schema.source + '/' + schema.object + '_' + schema.children[i].object + 's/' + id + '/', false)); /* fetch data synchronously */
	}
	return d;
}

/* override gladbooks.js function */
function displayElement() {
	// do nothing
}

function createObjects(schema, post) {
	var doc = '';
	/* loop through rows */
	$(schema.data).find('resources').find('row').each(function() {
		var xml = createObjectXML(schema, this);
		if (xml && post) {
			postDoc(schema.object, xml);
		}
		else {
			doc += xml;
		}
	});

	return doc;
}

function processFieldValues(schema, row) {
	var obj = new Object();

	/* loop through fields */
	$(row).children().each(function() {
		for (i=0; i< schema.attributes.concat(schema.fields).length; i++) {
			var fld = schema.attributes.concat(schema.fields)[i];
			if ((schema.fields.indexOf(this.tagName) != -1) ||
				(schema.attributes.indexOf(this.tagName) != -1)) 
			{
				/* this is a field we want to import */
				if ((this.tagName in schema.fieldmap) &&
				    (schema.fieldmap[this.tagName] != 'NULL'))
				{
					/* map this field to a different field name */
					obj[schema.fieldmap[this.tagName]] = $(this).text();
				}
				else {
					/* use field name unmapped */
					obj[this.tagName] = $(this).text();
				}
			}
		}
	});
	return obj;
}

function createObjectXML(schema, row) {
	var obj = processFieldValues(schema, row);

	/* build xml */
	var doc = '';
	doc += '<' + schema.object;
	doc = appendXMLFields(doc, obj, schema, true);  /* attributes */
	doc += '>';
	doc = appendXMLFields(doc, obj, schema, false); /* fields */

	if (schema.children) {
		var id = schema.id ? obj[schema.id] : obj[schema.object];
		d = fetchRelatedData(schema, id);
		$.when.apply(null, d)
		.done(function() {
			var args = Array.prototype.splice.call(arguments, 0);
			for (var i=0; i<=args.length; i++) {
				if (schema.children[i]) {
					schema.children[i].data = args[i];
					xml = createObjects(schema.children[i]);
					if (xml) {
						doc += xml;
					}
				}
			}
		});
	}
	doc += '</' + schema.object + '>';
	return doc;
}

/* append either the mapped or unaltered fields/attributes to the xml doc */
function appendXMLFields(doc, obj, schema, is_attribute) {
	if (is_attribute) {
		f = appendXMLAttr;
		fields = schema.attributes;
	}
	else {
		f = appendXMLTag;
		fields = schema.fields;
	}
	if (schema.fixRecord) {
		schema.fixRecord(obj);
	}
	for (i=0; i<fields.length; i++) {
		if (schema.fixValue) {
			obj[fields[i]] = schema.fixValue(fields[i], obj[fields[i]]);
		}
		if (schema.fieldmap[fields[i]]) {
			/* append using mapped field name, skipping NULL */
			if (schema.fieldmap[fields[i]] != 'NULL') {
				doc = f(doc, schema.fieldmap[fields[i]], obj[fields[i]]);
			}
		}
		else {
			/* au naturel */
			doc = f(doc, fields[i], obj[fields[i]]);
		}
	}
	if ((schema.appendF) && (! is_attribute)) {
		doc = schema.appendF(doc, obj); /* call schema's handler function */
	}
	return doc;
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
	if (((tagName == 'start_date') || (tagName == 'end_date'))
	&& (value == '0000-00-00'))
	{
		return doc; /* skip blank dates */
	}
	if ((value != null) && (value != 'NULL') && (value != 'None')){
		doc += '<' + tagName + '>' + escapeHTML(value) + '</' + tagName + '>';
	}
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
		fail: function() { 
			console.log(object + ' not created'); 
		},
	});
	return d;
}

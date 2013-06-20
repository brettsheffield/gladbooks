/* 
 * importer_config.js - gladbooks data import runner
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

function fetchData(src) {
    var d = new Array();
    d.push(getXML('/' + src + '/organisations/'));
    d.push(getXML('/' + src + '/products/'));
    return d;
}

function processData(src, xml) {
    /* import products */
    var products = new ImportSchema();
    products.object = 'product';
    products.source = src;
    products.attributes = ['import_id'];
    products.fields = ['product', 'account', 'nominalcode', 'shortname', 'description', 'price_buy', 'price_sell', 'price'];
    products.fieldmap = {'product':'import_id', 'nominalcode': 'account', 'price': 'price_sell'};
    products.data = xml[1];
    createObjects(products, true);

	var salesinvoices = new ImportSchema();
	salesinvoices.object = 'salesinvoice';
	salesinvoices.source = src;
	salesinvoices.attributes = ['salesorder'];
	salesinvoices.fields = ['period', 'taxpoint', 'issued', 'due', 'subtotal', 'tax', 'total', 'pdf', 'ponumber', 'emailtext'];
	salesinvoices.fieldmap = {};

	var salesorderitems = new ImportSchema();
    salesorderitems.object = 'salesorderitem';
	salesorderitems.source = src;
	salesorderitems.attributes =[];
	salesorderitems.fields = ['product', 'product_import', 'linetext', 'price', 'qty'];
	salesorderitems.fieldmap = {'product':'product_import'};

    var salesorders = new ImportSchema();
    salesorders.object = 'salesorder';
    salesorders.source = src;
    salesorders.attributes = ['salesorder', 'is_open'];
    salesorders.fields = ['organisation', 'ponumber', 'cycle', 'start_date', 'end_date'];
    salesorders.fieldmap = {};
	salesorders.children = [ salesorderitems, salesinvoices ];
	if (src == 'gladserv') {
		salesorders.fixValue = fixValueGladserv;
	}

    var contacts = new ImportSchema();
    contacts.object = 'contact';
    contacts.source = src;
    contacts.attributes = ['is_open'];
    contacts.fields = ['name', 'line_1', 'line_2', 'line_3', 'town', 'county', 'country', 'postcode', 'email', 'phone', 'phonealt', 'mobile', 'fax', 'is_billing', 'is_shipping'];
    contacts.fieldmap = {'is_billing':'NULL', 'is_shipping':'NULL'};
    /* handler to tack on relationships after the rest of the xml is built */
    contacts.appendF = handleContactRelationships;

    /* import organisations & contacts */
    var organisations = new ImportSchema();
    organisations.object = 'organisation';
	organisations.id = 'orgcode';
    organisations.source = src;
    organisations.attributes = ['account', 'organisation', 'is_active', 'is_suspended', 'is_vatreg'];
    organisations.fields = ['name', 'terms', 'vatnumber'];
    organisations.fieldmap = {'account':'orgcode', 'organisation':'orgcode'};
    organisations.data = xml[0];
    organisations.children = [ contacts, salesorders ];
    createObjects(organisations, true);

}

/* handle relationships for contacts */
function handleContactRelationships(doc, obj) {
    doc = appendXMLRelationship(doc, '0', '1');
    doc = appendXMLRelationship(doc, '1', obj.is_billing);
    doc = appendXMLRelationship(doc, '2', obj.is_shipping);
    return doc;
}

function fixValueGladserv(field, value) {
	if ((field == 'cycle') && (value >=2) && (! isNaN(value))) {
		/* cycles above 2 are off by one in old GS system */
		return (Number(value) - 1).toString();
	}
	else {
		return value;
	}
}

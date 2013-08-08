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
    var producttaxes = new ImportSchema();
	producttaxes.object = 'tax';
	producttaxes.source = src;
	producttaxes.attributes = ['id'];
    producttaxes.fields = ['tax'];
    producttaxes.fieldmap = {'tax':'id'};

    var products = new ImportSchema();
    products.object = 'product';
	products.id = 'import_id';
    products.source = src;
    products.attributes = ['import_id'];
    products.fields = ['product', 'account', 'nominalcode', 'shortname', 'description', 'price_buy', 'price_sell', 'price'];
    products.fieldmap = {'product':'import_id', 'nominalcode': 'account', 'price': 'price_sell'};
    products.data = xml[1];
	products.children = [ producttaxes ]
	products.fixValue = fixPFAccount;
    createObjects(products, true);

    var salesitems = new ImportSchema();
	salesitems.object = 'salesitem';
	salesitems.source = src;
	salesitems.attributes = ['id'];
    salesitems.fields = ['tax'];
    salesitems.fieldmap = {'tax':'id'};

	/* handle salesinvoices with no parent salesorder.  
	 * These get posted as direct children of the organisation, 
	 * before salesorders */
	var salesinvoices_detached = new ImportSchema();
	salesinvoices_detached.object = 'salesinvoice';
	salesinvoices_detached.attributes = ['import_id', 'invoicenum'];
	salesinvoices_detached.source = src;
	salesinvoices_detached.fields = ['id', 'period', 'taxpoint', 'issued', 'due', 'subtotal', 'tax', 'total', 'pdf', 'emailtext'];
	salesinvoices_detached.fieldmap = {'id':'import_id'};

	var salesinvoices = new ImportSchema();
	salesinvoices.object = 'salesinvoice';
	salesinvoices.source = src;
	salesinvoices.attributes = ['salesorder', 'import_id', 'invoicenum'];
	salesinvoices.fields = ['id', 'period', 'taxpoint', 'issued', 'due', 'subtotal', 'tax', 'total', 'pdf', 'emailtext'];
	salesinvoices.fieldmap = {'id':'import_id'};

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
    salesorders.fields = ['organisation', 'cycle', 'start_date', 'end_date'];
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
    organisations.children = [ contacts, salesinvoices_detached, salesorders ];
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

function fixPFAccount(field, value) {
	if (field == 'account') {
		/* account codes in PF system have 5 digits instead of 4 */
		return (Number(value.substring(0,2) + value.substring(3))+1).toString();
	}
	else {
		return value;
	}
}

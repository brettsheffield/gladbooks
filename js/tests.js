/* 
 * tests.js - gladbooks api qunit tests
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

g_username='betty';
g_password='ie5a8P40';
g_instance='test';
g_business='1';

module("Login");

test("build authentication hash", function() {
	// Base64 encode username and password
	var myhash = auth_encode("betty", "nobby");
	equal(myhash, "YmV0dHk6bm9iYnk=", myhash);

	// Quick decode test.
	var myclear = Base64.decode(myhash);
	equal(myclear, "betty:nobby", myclear);
});

/* do some POST testing */
module("Account");

test("create account (asset)", function() {
	var xml = createRequestXml();
	xml += '<account type="1000" description="Test ASSET account creation"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('accounts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (liability)", function() {
	var xml = createRequestXml();
	xml += '<account type="2000" description="Test LIABILITY account creation"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('accounts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (capital)", function() {
	var xml = createRequestXml();
	xml += '<account type="3000" description="Test CAPITAL account creation"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('accounts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (revenue)", function() {
	var xml = createRequestXml();
	xml += '<account type="4000" description="Test REVENUE account creation"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('accounts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (expenditure)", function() {
	var xml = createRequestXml();
	xml += '<account type="5000" description="Test EXPENDITURE account creation"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('accounts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (invalid type) - MUST be rejected", function() {
	var xml = createRequestXml();
	xml += '<account type="666" description="Test INVALID account creation is rejected"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('accounts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});

});

module("Contacts");

test("create contact", function() {
	var xml = createRequestXml();
	xml += '<contact><name>Ms Contact Name</name><line_1>Line 1</line_1><line_2>Line 2</line_2><line_3>Line 3</line_3><town>Townsville</town><county>County</county><country>Grand Europia</country><postcode>EU01 23RO</postcode><email>someone@example.com</email><phone>01234 5678</phone><phonealt>0123 123</phonealt><mobile>333 3333</mobile><fax>456 4567</fax></contact></data></request>';

	stop();
	$.ajax({
		url: collection_url('contacts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create billing contact for organisation", function() {
	var xml = createRequestXml();
	xml += '<contact><name>Mr Bill Contact</name><organisation id="1" is_billing="true"/></contact></data></request>';

	stop();
	$.ajax({
		url: collection_url('contacts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create shipping contact for organisation", function() {
	var xml = createRequestXml();
	xml += '<contact><name>Mrs Shipping Address</name><organisation id="1" is_shipping="true"/></contact></data></request>';

	stop();
	$.ajax({
		url: collection_url('contacts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update contact", function() {
	var xml = createRequestXml();
	xml += '<contact id="1"><name>Mrs Corrected Name O\'Malley</name></contact></data></request>';

	stop();
	$.ajax({
		url: collection_url('contacts') + 1,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("get contactlist", function() {
	stop();
	$.ajax({
		url: collection_url('contactlist'),
		type: 'GET',
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
});

module("Department");

test("create department", function() {
	var xml = createRequestXml();
	xml += '<department><name>'+ UUID() +'</name></department></data></request>';

	stop();
	$.ajax({
		url: collection_url('departments'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

module("Division");

test("create division", function() {
	var xml = createRequestXml();
	xml += '<division><name>'+ UUID() +'</name></division></data></request>';

	stop();
	$.ajax({
		url: collection_url('divisions'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

module("Journal");

test("journal entry - valid xml", function() {
	var xml = createRequestXml();
	xml += '<journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1100" amount="120.00" /> <credit account="2202" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: collection_url('journals'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
	
});

test("journal entry - invalid credentials MUST be rejected", function() {
	var tmppass = g_password;
	g_password='invalid_password';
	var xml = createRequestXml();
	xml += '<journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1100" amount="120.00" /> <credit account="2202" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: collection_url('journals'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});

	g_password=tmppass;
	
});

test("journal entry - xml does not match schema", function() {
	/* xml does not have a <debit> tag */
	var xml = createRequestXml();
	xml += '<journal transactdate="2013-01-01" description="My First Journal Entry"> <credit account="1100" amount="120.00" /> <credit account="2202" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: collection_url('journals'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

test("journal entry - invalid account number MUST be rejected", function() {
	/* account 999 does not exist */
	var xml = createRequestXml();
	xml += '<journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="999" amount="120.00" /> <credit account="2202" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: collection_url('journals'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

test("journal entry - unbalanced journal MUST be rejected", function() {
	/* amount of last credit is out by a penny */
	var xml = createRequestXml();
	xml += '<journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1100" amount="120.00" /> <credit account="2202" amount="20.00" /> <credit account="4000" amount="100.01" /> </journal></data></request>';

	stop();
	$.ajax({
		url: collection_url('journals'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

module("Organisation");

test("create organisation", function() {
	var xml = createRequestXml();
	xml += '<organisation><name>My nifty new organisation</name></organisation></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisations'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (name)", function() {
	var xml = createRequestXml();
	xml += '<organisation id="2"><name>My nifty new organisation name to test updates</name></organisation></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisations') + 2,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (terms)", function() {
	var xml = createRequestXml();
	xml += '<organisation id="2"><terms>14</terms></organisation></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisations') + 2,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (is_active)", function() {
	var xml = createRequestXml();
	xml += '<organisation id="2" is_active="false"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisations') + 2,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (is_suspended)", function() {
	var xml = createRequestXml();
	xml += '<organisation id="2" is_suspended="true"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisations') + 2,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (is_vatreg)", function() {
	var xml = createRequestXml();
	xml += '<organisation id="2" is_vatreg="true"/></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisations') + 2,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (vatreg)", function() {
	var xml = createRequestXml();
	xml += '<organisation id="2"><vatnumber>EU 123 45678</vatnumber></organisation></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisations') + 2,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("link organisation and contact", function() {
	var xml = createRequestXml();
	xml += '<organisation>1</organisation><contact>1</contact></data></request>';

	stop();
	$.ajax({
		url: collection_url('organisation_contacts'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("get organisation", function() {

	stop();
	$.ajax({
		url: collection_url('organisations') + 2,
		type: 'GET',
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
});


/*
 * UUID()
 * JavaScript UUID Generator, v0.0.1
 *
 * Copyright (c) 2009 Massimo Lombardo.
 * Dual licensed under the MIT and the GNU GPL licenses.
 */
function UUID() {
    var uuid = (function () {
        var i,
            c = "89ab",
            u = [];
        for (i = 0; i < 36; i += 1) {
            u[i] = (Math.random() * 16 | 0).toString(16);
        }
        u[8] = u[13] = u[18] = u[23] = "-";
        u[14] = "4";
        u[19] = c.charAt(Math.random() * 4 | 0);
        return u.join("");
    })();
    return {
        toString: function () {
            return uuid;
        },
        valueOf: function () {
            return uuid;
        }
    };
}

module("Instance");

test("create instance", function() {
	var xml = createRequestXml();
	xml += '<instance><name>' + UUID() +'</name></instance></data></request>';

	stop();
	$.ajax({
		url: collection_url('instances'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
});

test("get instance list", function() {
	stop();
	$.ajax({
		url: collection_url('instances'),
		type: 'GET',
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
});


module("Business");

test("create business", function() {
	var xml = createRequestXml();
	xml += '<business><name>' + UUID() +'</name></business></data></request>';

	stop();
	$.ajax({
		url: collection_url('businesses'),
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
});

test("get business list", function() {
	stop();
	$.ajax({
		url: collection_url('businesses'),
		type: 'GET',
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
});

module("Mathematics");

test("add two decimals", function() {
	total = '214.58';
	term1 = '35.76';
	term2 = '178.82';

	sum = decimalAdd(term1, term2);

	equal(sum, total, term1 + '+' + term2 + '!=' + sum);
	strictEqual(sum, total, term1 + '+' + term2 + '!=' + sum);
});

test("add two decimals with an uneven number of places", function() {
    total = '214.580';
	term1 = '35.760';
	term2 = '178.82';

	sum = decimalAdd(term1, term2);

	equal(sum, total, term1 + '+' + term2 + '!=' + sum);
	strictEqual(sum, total, term1 + '+' + term2 + '!=' + sum);
});


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
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/account/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><account type="a" description="Test ASSET account creation"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (liability)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/account/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><account type="l" description="Test LIABILITY account creation"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (capital)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/account/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><account type="c" description="Test CAPITAL account creation"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (revenue)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/account/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><account type="r" description="Test REVENUE account creation"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (expenditure)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/account/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><account type="e" description="Test EXPENDITURE account creation"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("create account (invalid type) - MUST be rejected", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/account/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><account type="z" description="Test INVALID account creation is rejected"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});

});

module("Department");

test("create department", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/department/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><department name="'+ UUID() +'"/></data></request>';

	stop();
	$.ajax({
		url: url,
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
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/division/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><division name="'+ UUID() +'"/></data></request>';

	stop();
	$.ajax({
		url: url,
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
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/journal/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <request><data><journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1001" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
	
});

test("journal entry - invalid credentials MUST be rejected", function() {
	g_username='betty';
	g_password='invalid_password';
	var url = "/test/journal/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <request><data><journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1001" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

test("journal entry - xml does not match schema", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/journal/";
	/* xml does not have a <debit> tag */
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <request><data><journal transactdate="2013-01-01" description="My First Journal Entry"> <credit account="1001" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

test("journal entry - invalid account number MUST be rejected", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/journal/";
	/* account 999 does not exist */
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <request><data><journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="999" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

test("journal entry - unbalanced journal MUST be rejected", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/journal/";
	/* amount of last credit is out by a penny */
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <request><data><journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1001" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.01" /> </journal></data></request>';

	stop();
	$.ajax({
		url: url,
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
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/organisations/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><organisation><name>My nifty new organisation</name></organisation></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (name)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/organisations/2";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><organisation id="2"><name>My nifty new organisation name to test updates</name></organisation></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (terms)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/organisations/2";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><organisation id="2"><terms>14</terms></organisation></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (is_active)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/organisations/2";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><organisation id="2" is_active="false"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (is_suspended)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/organisations/2";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><organisation id="2" is_suspended="true"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (is_vatreg)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/organisations/2";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><organisation id="2" is_vatreg="true"/></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});

test("update organisation (vatreg)", function() {
	g_username='betty';
	g_password='ie5a8P40';
	var url = "/test/organisations/2";
	var xml = '<?xml version="1.0" encoding="UTF-8"?><request><data><organisation id="2"><vatnumber>EU 123 45678</vatnumber></organisation></data></request>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		beforeSend: function (xhr) { setAuthHeader(xhr); },
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});

});


/*!
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

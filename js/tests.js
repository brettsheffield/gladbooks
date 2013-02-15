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


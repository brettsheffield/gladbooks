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
module("POST Testing");

test("journal entry - valid xml", function() {
	var url = "/test/journal/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1001" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		success: function(xml) { ok(true); start(); },
		error: function(xml) { ok(false); start(); },
	});
	
});

test("journal entry - xml does not match schema", function() {
	var url = "/test/journal/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <journal transactdate="2013-01-01" description="My First Journal Entry"> <credit account="1001" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

test("journal entry - invalid account number MUST be rejected", function() {
	var url = "/test/journal/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="999" amount="120.00" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

test("journal entry - unbalanced journal MUST be rejected", function() {
	var url = "/test/journal/";
	var xml = '<?xml version="1.0" encoding="UTF-8"?> <journal transactdate="2013-01-01" description="My First Journal Entry"> <debit account="1001" amount="120.01" /> <credit account="2001" amount="20.00" /> <credit account="4000" amount="100.00" /> </journal>';

	stop();
	$.ajax({
		url: url,
		type: 'POST',
		data: xml,
		contentType: 'text/xml',
		success: function(xml) { ok(false); start(); },
		error: function(xml) { ok(true); start(); },
	});
	
});

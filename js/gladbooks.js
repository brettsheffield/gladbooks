/* 
 * gladbooks.js - main gladbooks javascript functions
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

/* global variables **********************************************************/

g_menus = [
	[ 'bank.reconcile', getForm, 'bank', 'reconcile', 'Bank Reconciliation' ],
	[ 'bank.upload', getForm, 'bank', 'upload', 'Upload Bank Statement' ],
	[ 'bank.statement', getForm, 'bank', 'statement', 'View Bank Statement' ],
	[ 'banking', showHTML, 'help/banking.html', 'Banking', false ],
	[ 'contact.create', getForm, 'contact', 'create', 'Add New Contact' ],
	[ 'contacts', showQuery, 'contacts', 'Contacts', true ],
	[ 'departments.create', getForm, 'department', 'create', 'Add New Department' ],
	[ 'departments.view', showQuery, 'departments', 'Departments', true ],
	[ 'divisions.create', getForm, 'division', 'create', 'Add New Division' ],
	[ 'divisions.view', showQuery, 'divisions', 'Divisions', true ],
	[ 'help', showHTML, 'help/index.html', 'Help', false ],
	[ 'organisation.create', getForm, 'organisation', 'create', 'Add New Organisation' ],
	[ 'organisations', showQuery, 'organisations', 'Organisations', true ],
	[ 'payables', showHTML, 'help/payables.html', 'Payables', false ],
	[ 'product.create', getForm, 'product', 'create', 'Add New Product' ],
	[ 'products', showQuery, 'products', 'Products', true ],
	[ 'rpt_accountsreceivable', showQuery, 'reports/accountsreceivable', 'Accounts Receivable', true ],
	[ 'rpt_balancesheet', showHTML, 'reports/balancesheet','Balance Sheet',false, true ],
	[ 'rpt_profitandloss', showHTML, 'reports/profitandloss','Profit & Loss',false, true ],
	[ 'rpt_trialbalance', showQuery, 'reports/trialbalance', 'Trial Balance', false ],
	[ 'salesinvoices', showQuery, 'salesinvoices', 'Sales Invoices', true ],
	[ 'salesorder.create', getForm, 'salesorder', 'create', 'New Sales Order'],
	[ 'salesorders', showQuery, 'salesorders', 'Sales Orders', true ],
	[ 'salesorders.process', getForm, 'salesorder', 'process', 'Manual Billing Run' ],
	[ 'salespayment.create', getForm, 'salespayment', 'create', 'Enter Sales Payment' ],
	[ 'salespayments', showQuery, 'salespayments', 'Sales Payments', true ],
    [ 'business.create', getForm, 'business', 'create', 'Add New Business' ],
    [ 'businessview', showQuery, 'businesses', 'Businesses', true ],
    [ 'chartadd', getForm, 'account', 'create', 'Add New Account' ],
    [ 'chartview', showQuery, 'accounts', 'Chart of Accounts', true ],
    [ 'journal', setupJournalForm ],
    [ 'ledger', showQuery, 'ledgers', 'General Ledger', true ],
];

/* data sources for each form
 * NB: when populating combos, the XML returned MUST have fields called
 * "id" and "name" - use SQL AS to rename them if necessary
 */

g_formdata = [
    [ 'account', 'create', [ 'accounttypes' ], ],  
    [ 'bank', 'statement', [ 'accounts.asset' ], ],  
    [ 'bank', 'reconcile', [ 'accounts.asset' ], ],  
    [ 'bank', 'reconcile.data', ['bank.unreconciled','journal.unreconciled'],],
    [ 'bank', 'upload', [ 'accounts.asset' ], ],  
    [ 'journal', 'create',
		[ 'accounts', 'divisions', 'departments', 'organisations' ],
	],  
    [ 'product', 'create', [ 'accounts.revenue' ], ],
    [ 'salesorder', 'create', [ 'organisations', 'cycles', 'products' ], ],
    [ 'salesorder', 'update', [ 'organisations', 'cycles', 'products' ], ],
    [ 'salespayment', 'create',[ 'paymenttype', 'organisations', 'accounts.asset' ], ],
    [ 'salespayment', 'update',[ 'paymenttype', 'organisations', 'accounts.asset' ], ],
];

var g_max_ledgers_per_journal=7;
var g_frmLedger;
var g_xml_accounttype = '';
var g_xml_business = ''
var g_xml_relationships = '';

/* bank reconcilition types */
var rectype = {
	"suggested": 0,
	"journal": 1,
	"salesinvoices": 2,
	"salespayments": 3
};

/* functions ****************************************************************/

function addSalesOrderProductField(field, value, mytab) {
    if (value.length > 0) {
        mytab.find('input.nosubmit[name="' + field + '"]').val(value);
    }
}

function addSalesOrderProducts(tab, datatable, xml) {
    console.log('addSalesOrderProducts()');
    $(xml).find('resources').find('row').each(function() {
        var id = $(this).find('id').text();
        var product = $(this).find('product').text();
        var linetext = $(this).find('linetext').text();
        var price = $(this).find('price').text();
        var qty = $(this).find('qty').text();

        salesorderAddProduct(tab, datatable, id, product, linetext, price, qty);
    });
}

/* add row to datatable for each subform item - not used for salesorders */
function addSubFormRows(xml, datatable, view, tab) {
    console.log('addSubFormRows(' + view + ')');
    var i = 0;
    var id = 0;
    $(xml).find('resources').find('row').each(function() {
        var row = newRow(i);

        $(this).children().each(function() {
            if (this.tagName == 'id') {
                id = $(this).text();
            }
            else if (this.tagName == 'type') {
                row.append(relationshipCombo(datatable, $(this), id, tab));
            }
            else {
                row.append('<td class="' + view + '">' + $(this).text() + '</td>');
            }
        });

        /* append remove "X" button */
        row.append('<td class="removerow noclick">'
            + '<input type="hidden" name="id" value="'
            + id + '"/><button class="removerow">X</button></td>');

        if (view != 'product_taxes') {
            /* attach click event to edit elements of subform */
            row.find('td').not('.noclick').click(function() {
                var id = $(this).parent().find('input[name="id"]').val();
                var collection = view.split('_')[1].toLowerCase();
                displayElement(collection, id);
            });
        }

        datatable.append(row);

        i++;
    });
}

/* the selected bank account has changed - do something about that */
function bankChange() {
	console.log('bankChange()');
	var mytab = activeTab();
	var div = mytab.find('div.bank.data');

	var account = $(this).val();
	if (account == -1) { /* nothing selected */
		div.find('div.bank.target').children().fadeOut();
		div.find('div.bank.suspects').children().fadeOut();
		return false;
	}

	var action = getTabMeta(activeTabId(), 'action');
	if (action == 'reconcile') {
		bankReconcile(account);
	}
	else if (action == 'statement') {
		bankStatement(account);
	}
}

/* set up journal form based on row that was clicked */
function bankJournal(row) {
	console.log('bankJournal()');
	var t = activeTab();
	var journalForm = activeTab().data('journalForm');
	var j = t.find('div.accordion h3:nth-child(3)');
	var jtab = j.next();

	jtab.empty().append(journalForm); /* insert journal form */

	/* populate combos */
	jtab.find('select.populate:not(.sub)').populate(jtab);

	/* work out debit/credit dropdowns */
	var debit = row.find('div.xml-debit').text();
	var credit = row.find('div.xml-credit').text();
	var bdc = (debit > 0) ? 'debit' : 'credit'; /* bank debit/credit */
	var odc = (debit > 0) ? 'credit' : 'debit'; /* other debit/credit */

	/* clone a ledger row */
	var ledgers = jtab.find('fieldset.ledger');
	var l = ledgers.clone();

	/* populate first ledger entry */
	var account = t.find('div.bank.selector select.bankaccount').val();
	var bankid = row.find('div.xml-id').text();
	var date = row.find('div.xml-date').text();
	var description = row.find('div.xml-description').text();
	jtab.find('select.account').val(account);
	jtab.find('input.transactdate').val(date);
	jtab.find('input.description').val(description);
	var amount = (debit > 0) ? debit : credit;
	jtab.find('input.amount').val(amount);

	/* add more ledger lines */
	for (var x = 1; x < g_max_ledgers_per_journal; x++) {
		ledgers.append(l.clone());
	}

	/* set debit/credit dropdowns */
	jtab.find('select.type').val(odc);
	jtab.find('select.type').first().val(bdc);

	jtab.find('button.submit').click(function(event) {
		submitJournalEntry(event, jtab, bankid)
	});

	j.each(accordionClick); /* show journal form */
}

function bankReconcile(account) {
	console.log('bankReconcile()');
	var title = '';
	var div = activeTab().find('div.bank.target');
	var offset = 0;
	var limit = 30;
	var sort = false;
	var url = 'bank.unreconciled/' + account + '/' + limit + '/' + offset;
	var d = new Array(); /* array of deferreds */
	var journalDiv = $('');
	var jtab = activeTab().find('div.accordion h3:nth-child(3)').next();

	setTabMeta(jtab, 'object', 'journal');
	setTabMeta(jtab, 'action', 'create');

	showSpinner();
	activeTab().find('div.suspects').children().fadeOut();
	d.push(getXML(collection_url(url)));
	d.push(fetchFormData('journal', 'create'));
	$.when.apply(null, d)
	.done(function(bankdata) {
		divTable(div, bankdata);
		var args = Array.prototype.splice.call(arguments, 1);
		var html = args[0].shift().responseText;
		activeTab().data('journalForm', html);
		jtab.updateDataSources(args[0]);
		div.find('div.tr').click(clickBankRow);
		accordionize(activeTab().find('div.accordion'));
		hideSpinner();
	})
	.fail(function() {
		statusMessage('error loading data', STATUS_CRIT);
		hideSpinner();
	});
}

function bankStatement(account) {
	var mytab = activeTab();
	var div = mytab.find('div.bank.data');
	var limit = 20; 		/* FIXME - hardcoded */
	var offset = 0; 		/* FIXME - hardcoded */
	var sortfield = 'id'; 	/* FIXME - hardcoded */
	var asc = 'ASC';		/* FIXME - hardcoded */
	var title = '';
	var sort = false;
	var tabid = activeTabId();
	var object = getTabMeta(tabid, 'object');
	var action = getTabMeta(tabid, 'action');
	var url = object + '.' + action + '/' + account;
	url += '/' + limit + '/' + offset + '/' + sortfield + '/' + asc;
	showQuery(url, title, sort, div);
}

/* find suggestions for bank rec */
function bankSuggest(row) {
	console.log('bankSuggest()');
	var t = activeTab();
	var results = 0;
	var title = 'Suggested Matches (' + results + ')';
	t.find('div.accordion h3:nth-child(1)').text(title);
	if (results > 0) {
		/* suggestions found, show them */
		t.find('div.accordion h3:nth-child(1)').each(accordionClick);
	}
	else {
		/* nothing to suggest, make journal active instead */
		bankJournal(row);
	}
}

function clickBankRow() {
	console.log('clickBankRow()');
	var id = $(this).find('div.xml-id').text();
	console.log('bank row ' + id + ' selected');
	selectRowSingular($(this));
	statusHide();

	/* TODO: populate suspects panel */
	bankSuggest($(this));

	$('div.reconcile div.accordion').fadeIn();
}

/* override gladd.js function */
customFormEvents = function(tab, object, action, id) {
	var mytab = getTabById(tab);

	/* remove scrollbar from tablet - we'll handle this in the bank.data div */
	if (object == 'bank') mytab.addClass('noscroll');

	mytab.find('select.bankaccount').change(bankChange);
}

/* show the form, after setup is complete */
function finishJournalForm(tab) {
    var ledger_lines = 1;
    var jf = $('div.dataformdiv.template').clone();
    jf.removeClass('template');
    if (tab) {
        /* clear existing tab */
        tab.empty();
        tab.append(jf);
    }
    else {
        /* clone template into new tab */
        addTab('Journal Entry', jf, true);
    }

    /* add some ledger lines */
    var jl = jf.find('fieldset.ledger').clone();
    while (ledger_lines++ < g_max_ledgers_per_journal) {
        jf.find('form').append(jl.clone());
    }

    /* add datepicker */
    var transactdate = jf.find('.transactdate');
    var currentDate = new Date();
    transactdate.val($.now());
    transactdate.datepicker({
        dateFormat: "yy-mm-dd",
        constrainInput: true
    });
    transactdate.datepicker("setDate",currentDate);

    /* set up click() events */
    $('button#journalsubmit').click(function(event) {
        submitJournalEntry(event, jf);
    });

    /* set up blur() events */
    $('div.tablet.active.business'
                        + g_business).find('input.amount').each(function() {
        $(this).blur(function() {
            /* pad amounts to two decimal places */
            var newamount = decimalPad($(this).val(), 2);
            if (newamount == '0.00') {
                /* blank out zeros */
                $(this).val('');
            }
            else {
                $(this).val(newamount);
            }
        });
    });

    /* display the form */
    jf.fadeIn(300);
    jf.find('p.journalstatus').fadeOut(5000);

    /* set focus */
    jf.find(".description").focus();

    /* set up input validation events */
    /* TODO */

}

/* Populate Accounts Drop-Downs with XML Data */
function populateAccountsDDowns(xml, tab) {
    $('select.account').empty();
    $('select.account').append(
        $("<option />").val(0).text('<select account>')
    );
    $(xml).find('row').each(function() {
        var accountid = $(this).find('nominalcode').text();
        accountid = padString(accountid, 4); /* pad code with leading zeros */
        var accounttype = $(this).find('type').text();
        var accountdesc = accountid + " - " +
        $(this).find('account').text();

        $('select.account').append(
            $("<option />").val(accountid).text(accountdesc)
        );
    });

    finishJournalForm(tab);
}

function populateDepartmentsDDowns(xml, tab) {
    $('select.department').empty();
    $(xml).find('row').each(function() {
        var id = $(this).find('id').text();
        var name = $(this).find('name').text();
        $('select.department').append(
            $("<option />").val(id).text(name)
        );
    });
}

function populateDivisionsDDowns(xml, tab) {
    $('select.division').empty();
    $(xml).find('row').each(function() {
        var id = $(this).find('id').text();
        var name = $(this).find('name').text();
        $('select.division').append(
            $("<option />").val(id).text(name)
        );
    });
}

/* debits and credits */
function populateDebitCreditDDowns() {
    $('select.type:not(.populated)').empty();
    $('select.type:not(.populated)').append(
        $("<option />").val('debit').text('debit')
    );
    $('select.type:not(.populated)').append(
        $("<option />").val('credit').text('credit')
    );
    $('select.type:not(.populated)').addClass('populated');
}

function postBankData(xml) {
	var account = activeTab().find('select.bankaccount').val();
	console.log('Uploading bank statement to account ' + account);

	/* prefix account number to data*/
	$(xml).find('data').each(function() {
		$(this).prepend('<account>' + account + '</account>');
	});

	var flatxml = flattenXml(xml);

    showSpinner('Saving bank data...');
    $.ajax({
        url: collection_url('banks'),
        data: flatxml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) {
            hideSpinner();
            console.log("postBankData() succeeded");
        },
        error: function(xml) {
            hideSpinner();
            console.log("postBankData() failed");
        }
    });
}

function prepareSalesOrderData(tag) {
    /* FIXME: this simply doesn't work */
    console.log('salesorderitem: ' + tag.tagName);
    if (tag.tagName == 'product') {
        var p = activeTab().find(
            'select.nosubmit[name="' + tag.tagName + '"]'
        );
        p.find(
            'option[value="' + $(tag).text()  + '"]'
        ).attr('selected', 'selected');
        p.trigger("change");
    }
    else {
        activeTab().find(
            'input.nosubmit[name="' + tag.tagName + '"]'
        ).val($(tag).text());
    }
}

function productBoxClone(mytab, product) {
    var productBox = $('<td class="xml-product"></td>');
    var productCombo = mytab.find('select.product.nosubmit').clone(true);
    productCombo.removeAttr("id");
    productCombo.css({display: "inline-block"});
    productCombo.removeClass('chzn-done nosubmit');
    productCombo.addClass('chosify sub');
    productCombo.val(product);
    productCombo.find('option[value=-1]').remove();
    productCombo.appendTo(productBox);
    return productBox;
}

function relationshipCombo(datatable, tag, id, tab) {
    console.log('appending relationship combo');

    if (!g_xml_relationships) {
        /* FIXME - we're supposed to have relationship data here,
         * and we don't */
        console.log('Not in a relationship');
    }
    var combo = datatable.find('select.relationship.nosubmit').clone();

    combo.removeAttr("id");
    combo.css({display: "inline-block"});
    combo.removeClass('chzn-done nosubmit');
    combo.addClass('chosify sub');

    /* mark our selections */
    markComboSelections(combo, tag.text());

    var td = $('<td class="noclick">'
        + '<input type="hidden" name="id" value="' + id + '"/>');

    combo.change(function() {
        console.log('combo.change()');
        if (combo.hasClass('relationship')) {
            var trow = combo.parent();
            var org = getTabById(tab).find('input[name="id"]').first().val();
            var contact = trow.find('input[name="id"]').val();
            var relationships = new Array();
            for (var x=0; x < combo[0].options.length; x++) {
                if (combo[0].options[x].selected) {
                    relationships.push(x);
                }
            }
            relationshipUpdate(org, contact, relationships);
        }
    });
    td.append(combo);
    return td;
}

/* link contact to organisation */
function relationshipUpdate(organisation, contact, relationships, refresh) {
    console.log('Updating relationship');

    /* ensure we were called with required arguments */
    if (!organisation) {
        console.log('relationshipUpdate() called without organisation.  Aborting.');
        return false;
    }
    if (!contact) {
        console.log('relationshipUpdate() called without contact.  Aborting.');
        return false;
    }

    var xml = createRequestXml();

    xml += '<organisation id="' + organisation + '"/>';
    xml += '<contact id="' + contact + '"/>';
    xml += '<relationship id="0"/>'; /* base "contact" relationship */

    /* any other relationship types we've been given */
    if (relationships) {
        for (var x=0; x < relationships.length; x++) {
            xml += '<relationship id="' + relationships[x] + '"/>';
        }
    }

    xml += '</data></request>';

    console.log(xml);

    var url = collection_url('organisation_contacts') + organisation
    url += '/' + contact + '/';

    console.log('POST ' + url);
    $.ajax({
        url: url,
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        complete: function(xml) {
            console.log('relationship updated');
            if (refresh) {
                loadSubformData('organisation_contacts', organisation);
            }
        }
    });
}

function resetSalesOrderProductDefaults() {
    activeTab().find('select.product.nosubmit').each(function() {
        var parentrow = $(this).parent().parent();
        $(this).val('').trigger('liszt:updated');
        parentrow.find('input.linetext').attr('placeholder', 'Line Text');
        parentrow.find('input.price').attr('placeholder', '0.00');
        parentrow.find('input.linetext').val('');
        parentrow.find('input.price').val('');
        parentrow.find('input.qty').val('1');
        recalculateLineTotal(parentrow, activeTab());
    });
}

function salesorderAddProduct(tab, datatable, id, product, linetext, price, qty)
{
    console.log('salesorderAddProduct()');
    console.log('Adding product ' + product + ' to salesorder');
    var mytab = getTabById(tab);
    var row = $('<tr class="even"></tr>');

    if (product == null) {
        product = mytab.find('select.product.nosubmit').val();
    }
    if (linetext == null) {
        linetext = mytab.find('input[name$="linetext"]').val();
    }
    if (price == null) {
        price = mytab.find('input[name$="price"]').val();
    }
    if (qty == null) {
        qty = mytab.find('input[name$="qty"]').val();
    }

    statusHide();

    if (product == -1) {
        statusMessage('Please select a Product', STATUS_WARN);
        return; /* must select a product */
    }

    /* We're not saving anything yet - just building up a salesorder on the
     * screen until the user clicks "save" */

    if (id) {
        row.append('<input type="hidden" name="subid" value="' + id + '" />');
    }

    row.append(productBoxClone(mytab, product));

    if (id) {
        row.append('<input type="hidden" name="is_deleted" value="" />');
    }

    /* append linetext input */
    row.append(cloneInput(mytab, 'linetext', linetext));

    /* clone price input and events */
    row.append(cloneInput(mytab, 'price', price));

    /* clone qty input and events */
    row.append(cloneInput(mytab, 'qty', qty));

    /* clone total input and events */
    row.append(cloneInput(mytab, 'total'));

    row.append('<td class="removerow"><button class="removerow">X</button></td>');

    /* add handler to remove row */
    row.find('button.removerow').click(function () {
        $(this).parent().parent().fadeOut(300, function() {
            if ($(this).find('input[name="subid"]').val() != null) {
                $(this).find('input[name="is_deleted"]').val('1');
                $(this).find('input.total').val('0');
            }
            else {
                /* this item hadn't been saved yet, so just remove */
                $(this).remove();
            }
            updateSalesOrderTotals(tab);
        });
    });

    datatable.append(row);

    /* prettify the chosen() combos */
    datatable.find('select.chosify').each(function() {
        $(this).chosen();
        $(this).removeClass('chosify');
        $(this).trigger('change');
    });

    /* reset the defaults for next product */
    resetSalesOrderProductDefaults();

    updateSalesOrderTotals(tab);
}

function setupJournalForm(tab) {

    /* load dropdown contents */
    $.ajax({
        url: collection_url('divisions'),
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function (xml) {
            populateDivisionsDDowns(xml, tab);
        }
    });

    $.ajax({
        url: collection_url('departments'),
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function (xml) {
            populateDepartmentsDDowns(xml, tab);
        }
    });

    $.ajax({
        url: collection_url('accounts'),
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function (xml) {
            populateAccountsDDowns(xml, tab);
        }
    });

    populateDebitCreditDDowns();
}

function submitJournalEntry(event, form, bankid) {
    event.preventDefault();
    xml = validateJournalEntry(form, bankid);
    if (!xml) {
        return;
    }

    showSpinner();
    $.ajax({
        url: collection_url('journals'),
        type: 'POST',
        data: xml,
        contentType: 'text/xml',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) {
			console.log('success');
			if (bankid) {
				activeTab().find('select.bankaccount').change();
			}
			else {
				submitJournalEntrySuccess(xml, form);
			}
		},
        error: function(xml) { submitJournalEntryError(xml); }
    });
}

/* override the gladd.js function which sets tab titles */
tabTitle = function (title, object, action, xml) {
    if ((object == 'salesorder') && (action == 'update') && (xml[0])) {
        /* Display Sales Order number as tab title */
        title = 'SO ' + $(xml[0]).find('order').first().text();
    }
    else if ((object == 'contact') && (action == 'update') && (xml[0])) {
        /* Display Contact name as tab title */
        title = $(xml[0]).find('name').first().text();
    }
    else if ((object == 'organisation') && (action == 'update') && (xml[0])) {
        /* Display Organisation name as tab title */
        title = $(xml[0]).find('name').first().text();
    }
    return title;
}

/* apply tax to product */
function taxProduct(product, tax, refresh, tab) {
    console.log('Taxing product');
    var xml = createRequestXml();
    statusHide();

    /* prevent more than one VAT rate being applied to a single product */
    var has_tax = activeTab().find('td.product_taxes').text().indexOf('VAT');
    if ((has_tax > 0) && (tax <= 3)) {
        statusMessage("Only one type of VAT may be applied.", STATUS_WARN);
        return;
    }

    xml += '<tax id="' + tax + '">';
    xml += '<product>' + product + '</product>';
    xml += '</tax>';
    xml += '</data></request>';

    var url = collection_url('product_taxes');

    console.log('POST ' + url);
    $.ajax({
        url: url,
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        complete: function(xml) {
            if (refresh) {
                loadSubformData('product_taxes', product, tab);
            }
        }
    });
}

function updateSalesOrderTotals(tab) {
    /* FIXME: uncaught exception: NaN */
    console.log('Updating salesorder totals');

    var subtotal = Big('0.00');
    var taxes = Big('0.00');
    var gtotal = Big('0.00');
    var mytab = getTabById(tab);
    var x = 0;

    mytab.find('input.total:not(.clone)').each(function()
    {
        /* get line total, stripping commas */
        x = $(this).val().replace(',', '');
        if ((! isNaN(x)) && (x != '')) {
            subtotal = subtotal.plus(Big(x));
        }
    });

    gtotal = subtotal.plus(taxes);

    /* update sub total */
    subtotal = decimalPad(subtotal, 2);
    mytab.find('table.totals').find('td.subtotal').each(function()
    {
        $(this).text(formatThousands(subtotal));
    });

    /* update grand total */
    gtotal = decimalPad(gtotal, 2);
    mytab.find('table.totals').find('td.gtotal').each(function()
    {
        $(this).text(formatThousands(gtotal));
    });
}

function validateFormAccount(action, id) {
    var mytab = activeTab();

    console.log('validateFormAccount()');

    var type = mytab.find('select.type');
    if (type.val() < 0) {
        statusMessage('Please select an Account Type', STATUS_WARN);
        type.focus();
        return false;
    }

    var description = mytab.find('input.description');
    if (description.val().length < 1) {
        statusMessage('Please enter a Description', STATUS_WARN);
        description.focus();
        return false;
    }
    var codebox = mytab.find('input.nominalcode');
    var code = codebox.val();

    if (validateNominalCode(code, type.val()) == false) {
        codebox.focus();
        return false;
    }

    console.log('account form validates');

    return true;
}

function validateFormProduct(action, id) {
    var mytab = activeTab();

    var account = mytab.find('select.account');
    if (account.val() < 0) {
        statusMessage('Please select an Account', STATUS_WARN);
        account.focus();
        return false;
    }
    var shortname = mytab.find('input.shortname');
    if (shortname.val().length < 1) {
        statusMessage('Please enter a Short Name ', STATUS_WARN);
        shortname.focus();
        return false;
    }
    var description = mytab.find('input.description');
    if (description.val().length < 1) {
        statusMessage('Please enter a Description', STATUS_WARN);
        description.focus();
        return false;
    }

    return true;
}

function validateFormSalesOrder(action, id) {
    var mytab = activeTab();

    var customer = mytab.find('select.organisations');
    if (customer.val() < 0) {
        statusMessage('Please select a Customer', STATUS_WARN);
        customer.focus();
        return false;
    }
    var products = mytab.find('td.xml-product');
    if (products.length < 1) {
        statusMessage('Please add a Product to the Sales Order', STATUS_WARN);
        return false;
    }

    return true;
}

function validateJournalEntry(form, bankid) {
    var xml = createRequestXml();
    var account;
    var division = 0;
    var department = 0;
    var type;
    var amount;
    var debits = 0;
    var credits = 0;
    var debitxml = '';
    var creditxml = '';

    $(form).find('p.journalstatus').text("");

    /* ensure we have a description */
    if ($(form).find('.description').val().trim().length == 0) {
        statusMessage('A description is required', STATUS_WARN);
        xml = false;
        return false;
    }
    $(form).find('fieldset').children().each(function() {
        if ($(this).hasClass('description')) {
            xml = createRequestXml();
            xml += '<journal ';
            xml += 'transactdate="' + $(form).find('.transactdate').val()
                + '" ';
			if (bankid) xml += 'bankid="' + bankid + '" ';
            xml += 'description="'+ escapeHTML($(this).val().trim()) +'">';
        }
        else if ($(this).hasClass('account')) {
            account = $(this).val();
        }
        else if ($(this).hasClass('division')) {
            division = $(this).val();
        }
        else if ($(this).hasClass('department')) {
            department = $(this).val();
        }
        else if ($(this).hasClass('type')) {
            type = $(this).val();
        }
        else if ($(this).hasClass('amount')) {
            amount = $(this).val();
            console.log('amount: ' + amount);
            if ((Number(amount) > 0) && (Number(account) >= 0)) {
                if (type == 'debit') {
                    debits = decimalAdd(debits, amount);
                    debitxml += '<' + type + ' account="' + account;
                    debitxml += '" division="' + division;
                    debitxml += '" department="' + department;
                    debitxml += '" amount="' + amount + '"/>';
                }
                else if (type == 'credit') {
                    credits = decimalAdd(credits, amount);
                    creditxml += '<' + type + ' account="' + account;
                    creditxml += '" division="' + division;
                    creditxml += '" department="' + department;
                    creditxml += '" amount="' + amount + '"/>';
                }
            }
            console.log('debits: ' + debits);
            console.log('credits: ' + credits);
        }
    });
    if (xml) {
        xml += debitxml;
        xml += creditxml;
        xml += '</journal></data></request>';
    }

    /* quick check to ensure debits - credits = 0 */
    console.log('debits=' + debits);
    console.log('credits=' + credits);
    if (!(decimalEqual(debits, credits))) {
        statusMessage('Transaction is unbalanced', STATUS_WARN);
        xml = false;
    }
    if (decimalEqual(decimalAdd(debits, credits), 0)) {
        statusMessage('Transaction is zero', STATUS_WARN);
        xml = false;
    }

    return xml;
}

/* journal was posted successfully */
function submitJournalEntrySuccess(xml, form) {
    setupJournalForm(form);
    statusMessage('Journal posted', STATUS_INFO);
    hideSpinner();
}

/* problem posting journal */
function submitJournalEntryError(xml) {
    statusMessage('Error posting journal', STATUS_ERROR);
    hideSpinner();
}

/* return true iff nominal code is in range for type */
function validateNominalCode(code, type) {
    var xml = g_xml_accounttype;

    statusHide(); /* clear status box */

    if (code == '') {
        return true; /* blank code => auto-assign */
    }

    /* force arguments to be numeric */
    code = +(code);
    type = +(type);

    if (type < 0) { /* type not selected yet */
        console.log('type not selected');
        return true;
    }

    /* find row that refers to this type */
    var row = $(xml).find('id').filter(function() {
        return $(this).parent().find('id').text() == type;
    }).parent();

    var min = row.find('range_min').text();
    var max = row.find('range_max').text();
    var typename = row.find('name').text();
    var ret = false;

    console.log('code: ' + code);
    console.log('min: ' + min);
    console.log('max: ' + max);
    console.log('typename: ' + typename);

    if (code.length == 0) { /* blank is okay */
        console.log('nominal code is blank');
        return true;
    }
    else if (isNaN(code)) { /* must be a number */
        console.log('nominal code not a number');
        statusMessage('Nominal Code must be a number', STATUS_WARN);
        return false;
    }
    else if ((code < min) || (code > max)) { /* must be in defined range */
        console.log('nominal code out of range');
        statusMessage('Nominal Codes for ' + typename
            + ' must lie between ' + min + ' and ' + max, STATUS_WARN);
        return false;
    }
    else { /* ensure code hasn't been used */
        /* TODO */
    }
    console.log('Nominal code is within acceptable range');

    return true;
}


/* TODO  - functions that have Gladbooks-specific stuff in them: */
/* handleSubforms()
 * formEvents() - not really, but consider refactoring
 * uploadFile() - has hardcoded /fileupload/ destination
 * formBlurEvents()
 * displaySearchResults()
 * changeRadio()
 * recalculateLineTotal()
 * validateForm()
 * cloneInput()
 * populateCombos()
 * loadCombo()
 * populateCombo()
 * comboChange()
 * clearForm()
 * displaySubformData()
 * btnClickLinkContact()
 * btnClickRemoveRow()
 * submitForm()
 * submitFormSuccess()
 * submitFormError()
 * collectionObject()
 * fetchElementData()
 * displayResultsGeneric()
 * switchBusiness() - refers to orgcode
 * clickElement()
 */

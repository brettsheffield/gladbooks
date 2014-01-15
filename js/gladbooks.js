/* 
 * gladbooks.js - main gladbooks javascript functions
 *
 * this file is part of GLADBOOKS
 *
 * Copyright (c) 2012, 2013, 2014 Brett Sheffield <brett@gladbooks.com>
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
    [ 'bank.statement', getForm, 'bank', 'statement', 'Bank Statement' ],
    [ 'bank.test', showHTML, 'help/layouttest.html', 'Layout Test' ],
    [ 'banking', showHTML, 'help/banking.html', 'Banking', false ],
    [ 'contact.create', showForm, 'contact', 'create', 'Add New Contact' ],
    [ 'contacts', showQuery, 'contacts', 'Contacts', true ],
    [ 'departments.create', showForm, 'department', 'create', 'Add New Department' ],
    [ 'departments.view', showQuery, 'departments', 'Departments', true ],
    [ 'divisions.create', showForm, 'division', 'create', 'Add New Division' ],
    [ 'divisions.view', showQuery, 'divisions', 'Divisions', true ],
    [ 'help', showHTML, 'help/index.html', 'Help', false ],
    [ 'organisation.create', showForm, 'organisation', 'create', 'Add New Organisation' ],
    [ 'organisations', showQuery, 'organisations', 'Organisations', true ],
    [ 'payables', showHTML, 'help/payables.html', 'Payables', false ],
    [ 'product.create', showForm, 'product', 'create', 'Add New Product' ],
    [ 'products', showQuery, 'products', 'Products', true ],
    [ 'rpt_accountsreceivable', showQuery, 'reports/accountsreceivable', 'Accounts Receivable', true ],
    [ 'rpt_balancesheet', showHTML, 'reports/balancesheet','Balance Sheet',false, true ],
    [ 'rpt_profitandloss', showHTML, 'reports/profitandloss','Profit & Loss',false, true ],
    [ 'rpt_trialbalance', showQuery, 'reports/trialbalance', 'Trial Balance', false ],
    [ 'salesinvoices', showQuery, 'salesinvoices', 'Sales Invoices', true ],
    [ 'salesorder.create', showForm, 'salesorder', 'create','New Sales Order'],
    [ 'salesorders', showQuery, 'salesorders', 'Sales Orders', true ],
    [ 'salesorders.process', getForm, 'salesorder', 'process', 'Manual Billing Run' ],
    [ 'salespayment.create', getForm, 'salespayment', 'create', 'Enter Sales Payment' ],
    [ 'salespayments', showQuery, 'salespayments', 'Sales Payments', true ],
    [ 'business.create', getForm, 'business', 'create', 'Add New Business' ],
    [ 'businessview', showQuery, 'businesses', 'Businesses', true ],
    [ 'chartadd', showForm, 'account', 'create', 'Add New Account' ],
    [ 'chartview', showQuery, 'accounts', 'Chart of Accounts', true ],
    [ 'journal', setupJournalForm ],
    [ 'ledger', showQuery, 'ledgers', 'General Ledger', true ],
    [ 'logout', logout ],
];

/* data sources for each form
 * NB: when populating combos, the XML returned MUST have fields called
 * "id" and "name" - use SQL AS to rename them if necessary
 */

g_formdata = [
    [ 'bank', 'statement', [ 'accounts.asset' ], ],  
    [ 'bank', 'reconcile',
        [
            'accounts.unreconciled',
            'accounts',
            'divisions',
            'departments',
        ],
    ],  
    [ 'bank', 'reconcile.data', 
        [
            'bank.unreconciled',
            'journal.unreconciled',
        ],
    ],
    [ 'bank', 'upload', [ 'accounts.asset' ], ],  
    [ 'journal', 'create',
        [ 'accounts', 'divisions', 'departments', 'organisations' ],
    ],  
    [ 'salesorder', 'create', [ 'organisations', 'cycles', 'products' ], ],
    [ 'salesorder', 'update', [ 'organisations', 'cycles', 'products' ], ],
    [ 'salespayment', 'create',[ 'paymenttype', 'organisations', 'accounts.asset' ], ],
    [ 'salespayment', 'update',[ 'paymenttype', 'organisations', 'accounts.asset' ], ],
];

FORMDATA = {
    'account': {
        'create': [ 'accounttypes' ], 
        'update': [ 'accounttypes' ], 
    },  
    'organisation': {
        'update': [ 'contacts', 'relationships' ],
    },
    'product': {
        'create': [ 'accounts.revenue' ],
        'update': [ 'accounts.revenue', 'taxes' ],
    },
    'salesorder': {
        'create': [ 'cycles', 'organisations', 'productcombo' ],
        'update': [ 'cycles', 'organisations', 'productcombo' ],
    },
}

MAPFIELDS = {
    'contact': ['line_1','line_2','line_3','town','county', 'country',
                'postcode']
}

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

    /* reset offset in results pager */
    mytab.find('div.results.pager').data('offset', 0);
    mytab.find('div.results.pager').data('order', 'ASC');

    var action = TABS.active.action;
    if (action == 'reconcile') {
        bankReconcile(account);
        bankReconcileCancel();
    }
    else if (action == 'statement') {
        bankStatement(account);
    }
}

/* clear junk from div.entries */
function bankEntriesClear() {
    /* remove salesinvoices */
    var mytab = activeTab();
    mytab.find('div.bank.entries div.tr.salesinvoice').remove();
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

/* user has clicked journal Add button */
function bankJournalAdd() {
    console.log('bankJournalAdd()');
    var mytab = activeTab();
    var o = new Object();
    o.date = mytab.find('div.bank.target div.td.xml-date').text();
    o.description = mytab.find('div.journal input.description').val();
    o.nominal = mytab.find('div.journal select.nominalcode').val();
    o.division = mytab.find('div.journal select.division').val();
    o.department = mytab.find('div.journal select.department').val();
    o.debit = mytab.find('div.journal input.debit').val();
    o.credit = mytab.find('div.journal input.credit').val();

    /* validate */
    if (!bankJournalValidate(o)) { return false; }

    /* default description to bank entry */
    if (o.description.length == 0) {
        o.description = mytab.find('div.bank.target div.td.xml-description').text();
    }

    /* build fragment */
    var j = $('<div class="tr"/>');
    j.append('<div class="td xml-date">' + o.date + '</div>');
    j.append('<div class="td xml-description">' + o.description + '</div>');
    j.append('<div class="td xml-account">' + o.nominal + '</div>');
    j.append('<div class="td xml-debit">' + decimalPad(o.debit,2) + '</div>');
    j.append('<div class="td xml-credit">' + decimalPad(o.credit,2) +'</div>');
    j.append('<div class="td buttons"><button class="del">X</button></div>');
    j.find('button.del').click(bankJournalDel);

    /* append to entries */
    mytab.find('div.bank.entries').append(j);

    bankJournalReset();
    bankTotalsUpdate();
}

/* user clicked delete button on entry */
function bankJournalDel() {
    var mytab = activeTab();
    $(this).parents('div.tr').fadeOut(300, function() {
        if ($(this).hasClass('suggestion')) {
            var account = mytab.find('select.bankaccount').val();
            var div = mytab.find('div.bank.target');
            var row = div.find('div.tr div.td').parents('div.tr');
            bankSuggest(row, account);
        }
        $(this).remove();
        bankTotalsUpdate();
    });
}

/* Check new journal entry before adding to entries */
function bankJournalValidate(o) {
    if (o.nominal < 0) { return false; } /* TODO: report warning to user */
    if (decimalPad(o.debit,2) == '0.00' && decimalPad(o.credit,2) == '0.00') { 
        return false;
    }
    return true;
}

function bankJournalAmountChange() {
    /* check user entered somthing numeric */
    if (!$.isNumeric($(this).val())) {
        $(this).val('');
        return;
    }

    /* find our opposite number (debit/credit) */
    if ($(this).hasClass('debit')) {
        var opp = $(this).parents('div.tr').find('input.credit');
    }
    else {
        var opp = $(this).parents('div.tr').find('input.debit');
    }

    /* round and pad to 2 decimal places */
    var amount = decimalPad(roundHalfEven(Math.abs($(this).val()),2),2);

    /* if amount is negative, make positive and switch debit/credit */
    if ($(this).val() < 0) {
        opp.val(amount);
        $(this).val('');
    }
    else if ($(this).val() > 0) {
        opp.val(''); /* There can be only one */
        $(this).val(amount);
    }
    else {
        $(this).val(''); /* clear zero values */
    }
}

/* clear values and reset state of journal subform */
function bankJournalReset() {
    var mytab = activeTab();
    var journal = mytab.find('div.bank.journal');
    journal.show();
    journal.find('select').each(function() {
        $(this).val(-1);
        $(this).trigger('liszt:updated');
    });
    journal.find('input').val('');
    journal.find('input.amount').change(bankJournalAmountChange);
    journal.find('button.add').off().click(bankJournalAdd);
}

/* Display/recalculate bank totals */
function bankTotalsUpdate() {
    console.log('bankTotalsUpdate()');
    var mytab = activeTab();
    var debits = decimalPad(0, 2);
    var credits = decimalPad(0, 2);
    mytab.find('div.bank.total div.xml-debit').text(debits);
    mytab.find('div.bank.total div.xml-credit').text(credits);
    bankTotalsUpdated();
    mytab.find('div.bank.total').show();
    var target = mytab.find('div.bank.target div.xml-debit');
    var entries = mytab.find('div.bank.entries div.xml-debit');
    target.add(entries).each(function() {
        if ($.isNumeric($(this).text())) {
            debits = decimalAdd(debits, $(this).text());
            debits = decimalPad(debits, 2);
            mytab.find('div.bank.total div.xml-debit').text(debits);
            bankTotalsUpdated();
        }
    });
    var target = mytab.find('div.bank.target div.xml-credit');
    var entries = mytab.find('div.bank.entries div.xml-credit');
    target.add(entries).each(function() {
        if ($.isNumeric($(this).text())) {
            credits = decimalAdd(credits, $(this).text());
            credits = decimalPad(credits, 2);
            mytab.find('div.bank.total div.xml-credit').text(credits);
            bankTotalsUpdated();
        }
    });
}

/* called any time one of the totals is updated */
function bankTotalsUpdated() {
    console.log('bankTotalsUpdated()');
    var debits = mytab.find('div.bank.total div.xml-debit').text();
    var credits = mytab.find('div.bank.total div.xml-credit').text();
    var totals = mytab.find('div.bank.total div.xml-debit')
        .add(mytab.find('div.bank.total div.xml-credit'));
    var btnsave = mytab.find('div.results.pager button.save');
    if (debits == credits) { /* totals are balanced */
        totals.addClass('balanced');
        btnsave.removeAttr('disabled');
    }
    else {                   /* totals unbalanced */
        totals.removeClass('balanced');
        btnsave.attr('disabled','disabled');
    }
}

function bankReconcile(account) {
    console.log('bankReconcile()');
    var mytab = activeTab();
    var account = mytab.find('select.bankaccount').val();
    var title = '';
    var div = mytab.find('div.bank.target');
    var offset = mytab.find('div.results.pager').data('offset');
    var reverse = mytab.find('div.results.pager').data('reverse');
    var limit = 1;
    if (offset == undefined) { offset = 0; }
    if (reverse == undefined) { reverse = 'ASC'; }
    mytab.find('div.results.pager').data('offset', offset)
    mytab.find('div.results.pager').data('reverse', reverse)
    mytab.find('div.results.pager').data('limit', limit);
    var url = 'bank.unreconciled/' + account + '/' + limit + '/' + offset
        + '/' + reverse;
    var d = new Array(); /* array of deferreds */

    bankResultsPager(account, 'reconcile');
    bankJournalReset();
    bankTotalsUpdate();
    bankEntriesClear();

    /* set up save/cancel buttons */
    var btncancel = mytab.find('div.results.pager button.cancel');
    btncancel.off().click(bankReconcileCancel);
    btncancel.removeAttr('disabled');
    var btnsave = mytab.find('div.results.pager button.save');
    btnsave.attr('disabled','disabled');
    btnsave.off().click(bankReconcileSave);

    showSpinner();
    activeTab().find('div.suspects').children().fadeOut();
    d.push(getHTML(collection_url(url)));
    $.when.apply(null, d)
    .done(function(bankdata) {
        div.empty();
        if (bankdata != '(null)') {
            div.append(bankdata);
            var row = div.find('div.tr div.td').parents('div.tr');
            row.addClass('selected');
            div.show();
            bankTotalsUpdate(); 
            bankSuggest(row, account);
        }
        else {
            div.hide();
        }
        hideSpinner();
    })
    .fail(function() {
        statusMessage('error loading data', STATUS_CRIT);
        hideSpinner();
    });
}

/* cancel button clicked */
function bankReconcileCancel() {
    console.log('bankReconcileCancel()');
    var mytab = activeTab();
    mytab.find('div.bank.entries div.tr').fadeOut(300, function() {
        $(this).remove();
        bankTotalsUpdate();
    });
}

/* save button clicked */
function bankReconcileSave() {
    console.log('bankReconcileSave()');
    var mytab = activeTab();
    showSpinner('Saving...');

    if (mytab.find('div.entries div.tr.salesinvoice').length > 0) {
        var account = mytab.find('select.bankaccount').val();
        var bank = mytab.find('div.bank.target div.td.xml-id').text();
        bankReconcileSalesInvoice(bank, account);
        return;
    }
    
    /* Build request xml */
    var xml = createRequestXml();

    /* add target from bank statement */
    var target = '';
    var id = mytab.find('div.bank.target div.tr div.td.xml-id').text();
    var date = mytab.find('div.bank.target div.tr div.td.xml-date').text();
    var desc = mytab.find('div.bank.target div.tr div.td.xml-description')
        .text();
    var acct = mytab.find('div.bank.target div.tr div.td.xml-account').text();
    var debit = mytab.find('div.bank.target div.tr div.td.xml-debit').text();
    var credit = mytab.find('div.bank.target div.tr div.td.xml-credit').text();
    var amount = (debit > 0) ? debit : credit;
    xml += '<journal transactdate="' + date + '" description="' + desc + '">';

    /* our xsd schema requires debits to appear before credits */
    if (debit > 0) {
        xml += '<debit account="' + acct + '" amount="' + amount + '" ';
        xml += 'bankid="' + id + '"/>';
    }
    else {
        target = '<credit account="' + acct + '" amount="' + amount + '" ';
        target += 'bankid="' + id + '"/>';
    }

    /* add debits */
    mytab.find('div.bank.entries div.tr').each(function() {
        var amount = $(this).find('div.td.xml-debit').text();
        if (amount > 0) {
            xml += '<debit account="' + acct + '" amount="' + amount + '"/>';
        }
    });

    /* add credits */
    mytab.find('div.bank.entries div.tr').each(function() {
        var amount = $(this).find('div.td.xml-credit').text();
        if (amount > 0) {
            xml += '<credit account="' + acct + '" amount="' + amount + '"/>';
        }
    });
    xml += target;
    xml += '</journal></data></request>';
    console.log(xml);

    /* POST journal */
    showSpinner('Saving...');
    $.ajax({
        url: collection_url('journals'),
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) {
            hideSpinner();
            statusMessage('Saved.', STATUS_INFO, 5000);
            /* clean up, move on */
            bankReconcileCancel();
            mytab.find('div.results.pager button.next').trigger('click');
        },
        error: function(xml) {
            hideSpinner();
            statusMessage('Error saving journal', STATUS_CRIT);
        }
    });
}

/* set up pager buttons */
function bankResultsPager(account, action) {
    var mytab = activeTab();
    var pager = mytab.find('div.results.pager');
    console.log('bankResultsPager(' + account + ', ' + action + ')');
    pager.find('button.first').off().click(function() {
        bankResultsPagerFirst(pager, account, action);
        return false;
    });
    pager.find('button.previous').off().click(function() {
        bankResultsPagerPrevious(pager, account, action);
        return false;
    });
    pager.find('button.next').off().click(function() {
        bankResultsPagerNext(pager, account, action);
        return false;
    });
    pager.find('button.last').off().click(function() {
        bankResultsPagerLast(pager, account, action);
        return false;
    });
    pager.find('button.first,button.previous,button.next,button.last')
    .each(function() {
        $(this).removeAttr("disabled");
    });
}

function bankResultsPagerAction(account, action) {
    if (action == 'reconcile') {
        bankReconcile(account);
    }
    else if (action == 'statement') {
        bankStatement(account);
    }
}

function bankResultsPagerFirst(pager, account, action) {
    var order = pager.data('order');
    var reverse = (order == 'ASC') ? 'ASC' : 'DESC';
    pager.data('offset', 0);
    pager.data('reverse', reverse);
    bankResultsPagerAction(account, action);
}

function bankResultsPagerPrevious(pager, account, action) {
    var offset = pager.data('offset');
    var order = pager.data('order');
    var reverse = pager.data('reverse');
    var limit = pager.data('limit');
    if (order == reverse) {
        offset -= limit;
        if (offset < 0) { offset = 0 };
    }
    else {
        offset += limit;
    }
    pager.data('offset', offset);
    bankResultsPagerAction(account, action);
}

function bankResultsPagerNext(pager, account, action) {
    var offset = pager.data('offset');
    var order = pager.data('order');
    var reverse = pager.data('reverse');
    var limit = pager.data('limit');
    if (order == reverse) {
        offset += limit;
    }
    else {
        offset -= limit;
        if (offset < 0) { offset = 0 };
    }
    pager.data('offset', offset);
    bankResultsPagerAction(account, action);
}

function bankResultsPagerLast(pager, account, action) {
    var order = pager.data('order');
    var reverse = (order == 'ASC') ? 'DESC' : 'ASC';
    pager.data('offset', 0);
    pager.data('reverse', reverse);
    bankResultsPagerAction(account, action);
}

function bankStatement(account) {
    var mytab = activeTab();
    var div = mytab.find('div.bank.data');
    var pager = mytab.find('div.results.pager');
    var offset = pager.data('offset');
    var order = pager.data('order');
    var reverse = pager.data('reverse');
    var sortfield = pager.data('sortfield');

    /* work out how many rows we can fit on a screen */
    var hbox = mytab.find('div.bank.statement').height();
    var hhead = 20; /* 20 pixels */
    var hrow = 20;  /* 20 pixels */
    var limit = Math.floor((hbox-hhead)/hrow) - 2;

    /* set defaults */
    if (offset == undefined) { offset = 0; }
    if (order == undefined) { order = 'ASC'; }
    if (reverse == undefined) { reverse = 'ASC'; }
    if (sortfield == undefined) { sortfield = 'date'; }

    pager.data('limit', limit);
    pager.data('offset', offset);
    pager.data('order', order);
    pager.data('reverse', reverse);
    pager.data('sortfield', sortfield);

    var title = '';
    var sort = false;
    var tabid = activeTabId();
    var object = TABS.byId[tabid].object;
    var action = TABS.byId[tabid].action;
    var url = object + '.' + action + '/' + account;
    url += '/' + limit + '/' + offset + '/' + sortfield + '/' + order;
    url += '/' + reverse;
    showHTML(collection_url(url), title, div).done(bankStatementEvents);
    bankResultsPager(account, 'statement');
}

/* set up events on bank statement screen */
function bankStatementEvents() {
    var mytab = activeTab();
    mytab.find('div.bank.statement div.tr').off().click(bankStatementRowClick);
    mytab.find('div.bank.statement div.tr div.th').off()
        .click(bankStatementHeadingClick);
    mytab.find('div.pager button.unreconcile').off()
        .click(bankUnreconcileSelected);
    mytab.find('div.pager button.selectall').off()
        .click(bankStatementSelectAll);
    mytab.find('div.pager button.deselectall').off()
        .click(bankStatementSelectNone);
    pagerControls();
}

/* update state of pager controls depending on where we are in results */
function pagerControls() {
    var mytab = activeTab();
    var pager = mytab.find('div.results.pager');
    var limit = pager.data('limit');
    var offset = pager.data('offset');
    var order = pager.data('order');
    var reverse = pager.data('reverse');
    var reversed = (order != reverse);

    /* detect end of results */
    var rows = mytab.find('div.statement div.tr').length - 1;
    if (rows < limit) {
        if (!reversed) {
            /* partial results, assume end reached */
            pager.find('button.next').attr('disabled', 'disabled');
        }
        else {
            /* beginning reached with partial results - fetch full page */
            pager.find('button.previous').attr('disabled', 'disabled');
            pager.find('button.first').trigger('click');
        }
    }
    else {
        pager.find('button.previous').removeAttr('disabled');
        pager.find('button.next').removeAttr('disabled');
    }
    if (!reversed && offset == 0) {
        /* first position */
        pager.find('button.first').attr('disabled', 'disabled');
        pager.find('button.previous').attr('disabled', 'disabled');
    }
    else if (reversed && offset == 0) {
        /* end position */
        pager.find('button.next').attr('disabled', 'disabled');
        pager.find('button.last').attr('disabled', 'disabled');
    }
}

/* bank statement row was clicked */
function bankStatementRowClick() {
    var headers = $(this).find('div.th').length;
    if (headers > 0) {
        /* this is a heading row - ignore */
    }
    else {
        toggleSelected($(this));
        bankStatementHaveSelected();
    }
}

function bankStatementHeadingClick() {
    var heading = $(this).text();
    console.log('heading clicked: ' + heading);
    var mytab = activeTab();
    var pager = mytab.find('div.results.pager');
    var oldsort = pager.data('sortfield');
    var sortfield = oldsort;
    var order = pager.data('order');
    console.log('sortfield was ' + sortfield + ' ' + order);
    if (heading) {
        sortfield = heading;
        if (sortfield == oldsort) {
            console.log('heading == sortfield');
            /* sort in reverse order */
            var order = (order == 'ASC') ? 'DESC' : 'ASC';
            pager.data('order', order);
        }
        else {
            /* sort by new field, ASC */
            console.log('sorting by ' + sortfield);
            pager.data('sortfield', sortfield);
            pager.data('order', 'ASC');
        }
        var account = mytab.find('select.bankaccount').val();
        bankStatement(account);
    }
}

function bankStatementHaveSelected() {
    var mytab = activeTab();
    var selected = mytab.find('div.tr.selected').length;
    if (selected > 0) {
        mytab.find('div.pager button.unreconcile').removeAttr('disabled');
    }
    else {
        mytab.find('div.pager button.unreconcile').attr('disabled','disabled');
    }
}

function bankStatementSelectAll() {
    var row = activeTab().find('div.bank.data div.tr');
    selectAllRows(row);
    bankStatementHaveSelected();
}

function bankStatementSelectNone() {
    var row = activeTab().find('div.bank.data div.tr');
    deselectAllRows(row);
    bankStatementHaveSelected();
}

/* find suggestions for bank rec */
function bankSuggest(row, account) {
    console.log('bankSuggest()');
    var d = new Array();
    var id = $(row).find('div.xml-id').text();
    d.push(getHTML(collection_url('ledger.suggestions/' + id)));
    d.push(getHTML(collection_url('salesinvoice.suggestions/' + id)));
    $.when.apply(null, d)
    .done(function(html) {
        var docs = Array.prototype.splice.call(arguments, 0);
        bankSuggestResults(row, docs);
    })
    .fail(function() {
        bankJournal(row);
    });
    return d;
}

function bankSuggestResults(row, docs) {
    console.log('bankSuggestResults()')
    var results = 0;
    var rows = 0;
    var mytab = activeTab();
    var workspace = mytab.find('div.bank.suspects');
    workspace.empty();
    for (var i=0; i<docs.length; i++) {
        var html = docs[i][0];
        rows = $(html).find('div.bank.suggestion').length;
        results += rows;
        if (rows > 0) {
            /* suggestions found, show them */
            workspace.append(html);
            workspace.find('div.bank.suggestion').off().click(bankSuggestionClick);
        }
    }
}

/* User has clicked on a suggestion row */
function bankSuggestionClick() {
    var mytab = activeTab();
    var row = $(this);
    var account = mytab.find('select.bankaccount').val();
    var id = row.find('div.td.xml-id').text();
    var bank = mytab.find('div.bank.target div.td.xml-id').text();
    var date = mytab.find('div.bank.target div.td.xml-date').text();
    var amount = mytab.find('div.bank.target div.td.xml-debit').text();

    /* first, figure out what kind of row this is */
    if (row.hasClass('ledger')) {
        row = $(this).detach().off();
        console.log('suggestion type: ledger');
        bankReconcileId(bank, id, account);
    }
    else if (row.hasClass('salesinvoice')) {
        console.log('suggestion type: salesinvoice');
        toggleSelected(row);
        if (row.hasClass('selected')) {
            /* SI selected - add appropriate transactions to div.entries */
            var desc = $(this).find('div.td.xml-description').text();
            var subtotal = $(this).find('div.td.xml-subtotal').text();
            var tax = $(this).find('div.td.xml-tax').text();
            var total = $(this).find('div.td.xml-total').text();
            var org = $(this).find('div.td.xml-organisation').first().text();

            if (Number(amount) < Number(total)) {
                total = amount;
            }

            /* 1100 - Debtors Control */
            var dctl = $('<div class="tr salesinvoice"/>');
            dctl.append('<div class="td xml-id">' + id + '</div>');
            dctl.append('<div class="td xml-organisation">' + org + '</div>');
            dctl.append('<div class="td xml-date">' + date + '</div>');
            dctl.append('<div class="td xml-description">' + desc + '</div>');
            dctl.append('<div class="td xml-account">1100</div>');
            dctl.append('<div class="td xml-debit"/>');
            dctl.append('<div class="td xml-credit">' + total + '</div>');
            mytab.find('div.bank.entries').append(dctl);

            /* TODO: if VAT cash accounting, need an entry in 2200 - VAT */

        }
        else {
            /* SI unselected - remove from div.entries */
            mytab.find('div.entries div.tr.salesinvoice div.td.xml-id')
            .each( function() {
                if ($(this).text() == id) {
                    $(this).parents('div.tr.salesinvoice').remove();
                }
            });
        }
    }
    else {
        console.log('unknown suggestion type');
    }

    /* deal with overpayment */
    console.log('amount: ' + amount + '; total: ' + total);
    var overpay = amount;
    mytab.find('div.bank.suggestions div.tr.salesinvoice.selected')
    .each(function() {
        var sitotal = $(this).find('div.td.xml-total').text();
        console.log('decimalSubtract(' + overpay + ',' + sitotal +')');
        overpay = decimalPad(decimalSubtract(overpay, sitotal), 2);
    });

    /* append overpayment if required */
    mytab.find('div.bank.entries div.overpayment').remove();
    if (Number(overpay) > 0) {
        console.log('Overpayment: ' + overpay);
        /* overpayment - post to suspense account (9999) */
        var dctl = $('<div class="tr salesinvoice overpayment"/>');
        dctl.append('<div class="td xml-id">' + id + '</div>');
        dctl.append('<div class="td xml-organisation">'+org+'</div>');
        dctl.append('<div class="td xml-date">' + date + '</div>');
        dctl.append('<div class="td xml-description">Unallocated</div>');
        dctl.append('<div class="td xml-account">9999</div>');
        dctl.append('<div class="td xml-debit"/>');
        dctl.append('<div class="td xml-credit">' + overpay +'</div>');
        mytab.find('div.bank.entries').append(dctl);
    }
    bankTotalsUpdate();
}

function bankReconcileSalesInvoice(bank, account) {
    console.log('bankReconcileSalesInvoice()');
    var mytab = activeTab();
    var account = mytab.find('select.bankaccount').val();
    var date = mytab.find('div.bank.target div.td.xml-date').text();
    /* 1=cash; 2=cheque; 3=bank transfer */
    var paymenttype = '3'; /* FIXME: hardcoded */
    var org = mytab.find('div.bank.entries div.td.xml-organisation').first().text();
    var amount = mytab.find('div.bank.target div.td.xml-debit').text();
    var desc = mytab.find('div.bank.target div.td.xml-description').text();

    /* create salespayment */
    var xml = createRequestXml();
    xml += '<salespayment>';
    xml += '<transactdate>' + date + '</transactdate>';
    xml += '<paymenttype>' + paymenttype + '</paymenttype>';
    xml += '<organisation>' + org + '</organisation>';
    xml += '<bank>' + bank + '</bank>';
    xml += '<bankaccount>' + account + '</bankaccount>';
    xml += '<amount>' + amount + '</amount>';
    xml += '<description>' + desc + '</description>';

    /* allocate salespayment against salesinvoice(s) */
    mytab.find('div.bank.entries div.tr.salesinvoice').each(function() {
        var siid = $(this).find('div.td.xml-id').text();
        amount = $(this).find('div.td.xml-credit').text();
        xml += '<salespaymentallocation>';
        xml += '<salesinvoice>' + siid + '</salesinvoice>';
        xml += '<amount>' + amount + '</amount>';
        xml += '</salespaymentallocation>';
    });
    xml += '</salespayment></data></request>';

    $.ajax({
        url: collection_url('salespayments'),
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) {
            hideSpinner();
            statusMessage('Saved.', STATUS_INFO, 5000);
            bankReconcile(account); /* show next */
        },
        error: function(xml) {
            hideSpinner();
            statusMessage('Error reconciling transaction', STATUS_CRIT);
        }
    });
}

function bankReconcileId(bank, ledger, account) {
    console.log('Reconciling bank entry ' + bank + ' against ledger ' +ledger);

    /* Build request xml */
    var xml = createRequestXml();
    xml += '<account>' + account + '</account>';
    xml += '<bank id="' + bank + '">'; 
    xml += '<ledger>' + ledger + '</ledger>';
    xml += '</bank></data></request>';

    showSpinner('Reconciling bank item...');
    $.ajax({
        url: collection_url('banks') + bank,
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) {
            hideSpinner();
            statusMessage('Saved.', STATUS_INFO, 5000);
            bankReconcile(account); /* show next */
        },
        error: function(xml) {
            hideSpinner();
            statusMessage('Error unreconciling transaction', STATUS_CRIT);
        }
    });
}

function bankUnreconcileId(id, account, row) {
    console.log('Unreconciling bank entry ' + id);

    /* Build request xml */
    var xml = createRequestXml();
    xml += '<account>' + account + '</account>';
    xml += '<bank id="' + id + '">'; 
    xml += '<ledger>0</ledger>';
    xml += '</bank></data></request>';

    showSpinner('Unreconciling bank item ' + id + '...');
    $.ajax({
        url: collection_url('banks') + id,
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(xml) {
            hideSpinner();
            statusMessage('Saved.', STATUS_INFO, 5000);
            row.removeClass('reconciled');
        },
        error: function(xml) {
            hideSpinner();
            statusMessage('Error unreconciling transaction', STATUS_CRIT);
        }
    });
}

function bankUnreconcileSelected() {
    var mytab = activeTab();
    var selected = mytab.find('div.tr.selected').length;
    var account = mytab.find('div.bank.selector select.bankaccount').val();
    console.log(selected + ' rows selected');
    mytab.find('div.tr.selected.reconciled').each(function() {
        var id = $(this).find('div.td.xml-id').text();
        bankUnreconcileId(id, account, $(this));
    });
}

function clickBankRow() {
    console.log('clickBankRow()');
    var id = $(this).find('div.xml-id').text();
    console.log('bank row ' + id + ' selected');
    selectRowSingular($(this));
    statusHide();
    var account = activeTab().find('select.bankaccount').val();

    /* populate suspects panel */
    bankSuggest($(this), account);
}

/* override gladd.js function */
customFormEvents = function(tab, object, action, id) {
    var mytab = getTabById(tab);

    /* remove scrollbar from tablet - we'll handle this in the bank.data div */
    if (object == 'bank') mytab.addClass('noscroll');

    /* upload button click handler */
    mytab.find('button.upload').click(function()
    {
        uploadFile(csvToXml, '/fileupload/' + g_instance + '/');
    });

    mytab.find('select.bankaccount').change(bankChange);

    if (object == 'bank' && action == 'reconcile') {
        var acct = mytab.find('select.bankaccount').val();
        console.log('Bank: ' + acct);
        if (!acct) {
            /* no unreconciled transactions */
            console.log('no unreconciled transactions');
            mytab.find('div.bank.reconcile').empty();
            closeTab(tab);
            getForm('bank', 'upload', 'Upload Bank Statement');
            return;
        }
        else {
            /* Select first item in bank list */
            mytab.find('select.bankaccount').trigger('change');
        }
    }
    if (object == 'contact' && action == 'update') {
        var addressFields = ['line_1','line_2','line_3','town','county',
            'country','postcode'];
        var selector = addressFields.join('"],input[name="'); 
        selector = 'input[name="' + selector + '"]';
        mytab.find(selector).change(mapUpdate);
    }
}

customBusinessNotFound = function(xml) {
    getForm('business', 'create', 'Add New Business');
}

customLoginEvents = function(xml) {
    console.log('customLoginEvents.gladbooks()');
    g_instance = $(xml).find('instance').text();
    if (g_instance == '') {
        /* couldn't find instance for user - treat as failed login */
        loginfailed();
    }
    else {
        /* have instance, hide login dialog and get list of businesses */
        console.log('Instance selected: ' + g_instance);
        g_loggedin = true;
        hideLoginBox();
        prepBusinessSelector();
        $('input.search-query').off().change(searchKeyPress);
        /* TODO */
        //dashboardShow();
    }
}

customLogoutActions = function() {
    $('input.search-query').val(''); /* clear search bar */
}

function csvToXml(doc) {
    showSpinner('Converting csv to xml...');

    var sha = $(doc).find('sha1sum').text();
    if (sha.length != 40) {
        console.log('invalid sha1sum');
        return false;
    }
    $.ajax({
        url: collection_url('csvtoxml/' + sha),
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        dataType: 'xml',
        success: function(xml) {
            xml = fixXMLDates(xml);
            xml = fixXMLRequest(xml);
            postBankData(xml);
        },
        error: function(xml) {
            displayResultsGeneric(xml, collection, title);
        }
    });
}

/* load/refresh/display user dashboard */
function dashboardShow() {
    addTab('Dashboard', '<div class="dashboard"/>', true);
}

docKeypress = function() {
    var c = $(document.activeElement); /* find control with focus */
    if (c.hasClass('search-query')) {
        searchKeyPress();
    }
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
        var accountid = $(this).find('id').text();
        accountid = padString(accountid, 4); /* pad code with leading zeros */
        var accountdesc = $(this).find('name').text();
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
            statusMessage('Bank Statement uploaded', STATUS_INFO, 5000);
        },
        error: function(xml) {
            hideSpinner();
            console.log("postBankData() failed");
            statusMessage('Error processing bank statement', STATUS_CRIT);
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

/* key pressed in search bar - wait until user pauses before searching */
var t;
function searchKeyPress() {
    var c = $(document.activeElement); /* find control with focus */
    var ms = 400; /* 400ms delay */
    t = Date.now() + ms;
    window.setTimeout(searchLater, ms, c);
}

/* if no keys have been pressed since time was set, begin search */
function searchLater(c) {
    if (t <= Date.now()) {
        searchNow(c);
    }
}

/* begin search */
function searchNow(c) {
    var terms = searchTerms(c.val());
    var searchurl = 'search/';

    var d = getXML('/testdata/search.xml');
    d.done(function(xml) {
        searchStart(xml, terms);
    })
    .fail(function() {
        console.log('failed to get search definitions');
    });
}

function searchStart(doc, terms) {
    /* join terms into xml fragment */
    var termstring = '';
    if (terms.words.length > 0 && terms.words[0] != '') {
        termstring = '<term>' + terms.words.join('</term><term>') + '</term>';
    }
    if (terms.numbers.length > 0 && terms.numbers[0] != '') {
        termstring += '<term type="numeric">' + terms.numbers.join('</term><term type="numeric">') + '</term>';
    }
    if (terms.dates.length > 0 && terms.dates[0] != '') {
        termstring += '<term type="date">' + terms.dates.join('</term><term type="date">') + '</term>';
    }
    /* do not attempt search without any search terms */
    if (termstring.length == 0) { return; }

    $(doc).find('request').prepend('<business>' + g_business + '</business>');
    $(doc).find('request').prepend('<instance>' + g_instance + '</instance>');
    $(doc).find('search').prepend(termstring);
    var xml = flattenXml(doc);
    $.ajax({
        url: collection_url('search'),
        type: 'POST',
        data: xml,
        contentType: 'text/xml',
        beforeSend: function (xhr) { setAuthHeader(xhr); },
        success: function(html) {
            console.log('search complete');
            if (html == '(null)') { return; }
            html = html.replace(/&lt;div([^&]+)&gt;/g,'<div$1>');
            html = html.replace('&lt;/div&gt;','</div>', 'g');
            addTab('Search', html, true);
            searchEvents();
        },
        error: function(xml) {
            console.log('search failed');
        }
    });
}

/* add events to search results list */
function searchEvents() {
    var mytab = activeTab();
    mytab.find('div.search.results div.tr').click(searchRowClick);
}

function searchRowClick() {
    var id = $(this).find('div.td.id').text();
    if ($(this).hasClass('contact')) {
        console.log('contact ' + id);
        var name = $(this).find('div.td.name').text();
        showForm('contact', 'update', name, id);
    }
    if ($(this).hasClass('organisation')) {
        console.log('organisation ' + id);
        var name = $(this).find('div.td.name').text();
        showForm('organisation', 'update', name, id);
    }
    if ($(this).hasClass('product')) {
        console.log('product ' + id);
        displayElement('products', id);
    }
    if ($(this).hasClass('salesinvoice')) {
        console.log('salesinvoice ' + id);
        var ref = $(this).find('div.td.ref').text();
        var si = 'SI-' + ref.replace('/','-') + '.pdf';
        var url = '/pdf/' + g_orgcode + '/' + si;
        window.open(url);
    }
}

/* split search into terms */
function searchTerms(search) {
    search = search.trim();
    var terms = new Object();
    var tokens = new Array();
    terms.numbers = new Array();
    terms.dates = new Array();
    terms.words = search.split(/[\s]+/);
    var z = 0;

    if (terms.words.length > 1) {
        terms.words.unshift(search); /* add full search string as term */
        z = 1;
    }
    for (var i=z; i < terms.words.length; i++) {
        /* split the word down further and add these as extra search terms */
        if (isDate(terms.words[i])) {
            /* date - move to terms.dates */
            terms.dates.push(terms.words[i]);
            terms.words.splice(i, 1);
        }
        else if (isNaN(terms.words[i])) { /* don't split numbers */
            var tok = terms.words[i].split(/[\W]+/);
            if (tok.length > 1) {
                for (var j=0; j < tok.length; j++) {
                    tokens.push(tok[j]);
                }
            }
        }
        else {
            /* number - move to terms.numbers */
            terms.numbers.push(terms.words[i]);
            terms.words.splice(i, 1);
        }
    }
    terms.words = terms.words.concat(tokens);
    if (terms.words.length == 1 && terms.words[0] == '') { return null; }
    return terms;
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
    var namedobjects = [ 'contact', 'department', 'division', 'organisation',
        'product'
    ];

    if (namedobjects.indexOf(object) != -1 && action == 'update' && xml[0]) {
        if (object == 'product') {
            title = $(xml[0]).find('shortname').first().text();
        }
        else if (object == 'salesorder') {
            title = 'SO ' + $(xml[0]).find('order').first().text();
        }
        else {
            title = $(xml[0]).find('name').first().text();
        }
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

    var tab = TABS.active;
    var form = tab.form;

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
    var row = $(form.data['accounttypes']).find('row').filter(function() {
        return $(this).find('id').text() == type;
    });
    console.log(row);

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



function customBlurEvents(tab) {
    var mytab = getTabById(tab);
    mytab.find('input.price').each(function() {
        $(this).blur(function() {
            /* pad amounts to two decimal places */
            if ($(this).val().length > 0) {
                var newamount = decimalPad($(this).val(), 2);
                $(this).val(newamount);
            }
        });
    });
    mytab.find('input.price, input.qty').each(function() {
        $(this).blur(function() {
            recalculateLineTotal($(this).parent().parent(), tab);
        });
    });
}

function customComboChange(combo, xml, tab) {
    var id = combo.attr('id');
    var newval = combo.val();
    var mytab = isTabId(tab) ? getTabById(tab) : tab;

    console.log('Value of ' + id + ' combo has changed to ' + newval);

    /* deal with chart form type combo */
    if (combo.attr('name') == 'type') {
        var code = activeTab().find('input.nominalcode').val();
        return validateNominalCode(code, newval);
    }

    /* in the salesorder form, dynamically set placeholders to show defaults */
    if (mytab.find('div.salesorder')) {
        $(xml).find('row').find('id').each(function() {
            if ($(this).text() == newval) {
                var desc = $(this).parent().find('description').text();
                var price = $(this).parent().find('price_sell').text();
                price = decimalPad(price, 2);
                var parentrow = combo.parent().parent();
                parentrow.find('input.linetext').attr('placeholder', desc);
                parentrow.find('input.price').attr('placeholder', price);
                recalculateLineTotal(parentrow, tab);
            }
        });
    }
}

/*****************************************************************************/
/* recalculate line total */
function recalculateLineTotal(parentrow, tab) {
    console.log('recalculateLineTotal()');
    var p = parentrow.find('input.price').val();
    var q = parentrow.find('input.qty').val();

    /* if price is blank, use placeholder value */
    if (!p) {
        p = parentrow.find('input.price').attr('placeholder');
    }
    if (isNaN(p)) {
        p = 0;
    }
    if (isNaN(q)) {
        q = 0;
    }
    p = new Big(p);
    q = new Big(q);
    var t = p.times(q);
    t = decimalPad(roundHalfEven(t, 2), 2);
    var inputtotal = parentrow.find('input.total');
    var oldval = inputtotal.val();
    inputtotal.val(formatThousands(t));
    if (oldval != t) {
        updateSalesOrderTotals(tab);
    }
}

function customFormValidation(object, action, id) {
    if (object == 'account') {
        return validateFormAccount(action, id);
    }
    else if (object == 'product') {
        return validateFormProduct(action, id);
    }
    else if ((object == 'salesorder') && (action != 'process')) {
        return validateFormSalesOrder(action, id);
    }
    return true;
}

customSubmitFormSuccess = function(object, action, id, collection, xml) {
    if ((object == 'salesorder') && (action == 'process')) {
        statusMessage('Billing run successful', STATUS_INFO, 5000);
    }
    else {
        statusMessage(object + ' saved', STATUS_INFO, 5000);
    }

    if (object == 'business') {
        /* update business selector and switch business */
        TABS.active.close();
        g_business = $(xml).find('resources > row > id').text();
        prepBusinessSelector();
        hideSpinner();
        return false;
    }
    return true;
}

customClickElement = function(row) {
    console.log('customClickElement()');
    var tab = TABS.active;
    var action = 'update';

    /* Some collections should never do anything when clicked */
    var inert = [ 'salespayments' ];
    if (inert.indexOf(tab.collection) != -1) { return true; }

    if (['accounts','contacts','divisions','departments','organisations',
    'salesorders']
    .indexOf(tab.collection) !== -1) 
    {
        var id = row.find('td.xml-id').text();
        var name = row.find('td.xml-name').text();
        var object = tab.collection.substr(0,tab.collection.length-1);
        showForm(object, action, name, id);
        return true;
    }
    else if (tab.collection == 'products') {
        var id = row.find('td.xml-id').text();
        var name = row.find('td.xml-shortname').text();
        showForm('product', 'update', 'Product: ' + name, id);
        return true;
    }
    if (tab.collection == 'salesinvoices') {
        /* view salesinvoice pdf */
        var a=row.find('td.xml-pdf').find('a');
        var href=a.attr('href');
        var si = a.attr('id');
        var html = '<div class="pdf">';
        html += '<object class="pdf" data="' + href + '"';
        html += 'type="application/pdf">';
        html += 'alt : <a href="' + href + '">PDF</a>';
        html += '</object></div>';
        addTab(si, html, true);
        return true;
    }
    else {
        var id = row.find('td.xml-id').text();
        if (tab.collection === 'reports/accountsreceivable') {
            var title = 'Statement: ' + row.find('td.xml-orgcode').text();
        }
        else {
            var title = null;
        }
        displayElement(tab.collection, id, title);
        return true;
    }
}

Form.prototype.customXML = function() {
    if (this.object === 'product') {
        this.xml += '<tax id="1"/>';
    }
}

Form.prototype.submitErrorCustom = function(xhr, s, err) {
    if (this.object === 'salesorder' && this.action === 'process') {
        statusMessage('Billing run failed', STATUS_CRIT);
        return true;
    }
    return false;
}


/* TODO  - gladd.js functions that have Gladbooks-specific stuff in them: */
/* handleSubforms()
 * formEvents() - not really, but consider refactoring
 * displaySearchResults()
 * changeRadio()
 * cloneInput()
 * populateCombos()
 * loadCombo()
 * populateCombo()
 * clearForm()
 * displaySubformData()
 * btnClickLinkContact()
 * btnClickRemoveRow()
 * submitForm()
 * submitFormError()
 * collectionObject()
 * fetchElementData()
 * displayResultsGeneric()
 * switchBusiness() - refers to orgcode
 */


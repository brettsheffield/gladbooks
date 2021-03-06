/* 
 * gladbooks.js - main gladbooks javascript functions
 *
 * this file is part of GLADBOOKS
 *
 * Copyright (c) 2012-2015 Brett Sheffield <brett@gladbooks.com>
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

g_gladbooks_version = '0.2.1a';
g_gladd_version_req = '1.0.6';
console.log('Loaded gladbooks.js version ' + g_gladbooks_version);
if (!requireGladdJs(g_gladd_version_req)) {
    throw "gladd.js version " + g_gladd_version_req + " or greater required."
}

g_menus = [
    ['bank.reconcile', getForm, 'bank', 'reconcile', 'Bank Reconciliation'],
    ['bank.upload', getForm, 'bank', 'upload', 'Upload Bank Statement'],
    ['bank.statement', getForm, 'bank', 'statement', 'Bank Statement'],
    ['bank.test', showHTML, 'help/layouttest.html', 'Layout Test'],
    ['banking', showHTML, 'help/banking.html', 'Banking', false],
    ['contact.create', showForm, 'contact', 'create', 'Add New Contact'],
    ['contacts', showQuery, 'contacts', 'Contacts', true],
    ['departments.create', showForm, 'department', 'create', 'Add New Department'],
    ['departments.view', showQuery, 'departments', 'Departments', true],
    ['divisions.create', showForm, 'division', 'create', 'Add New Division'],
    ['divisions.view', showQuery, 'divisions', 'Divisions', true],
    ['help', showHTML, 'help/index.html', 'Help', false],
    ['organisation.create', showForm, 'organisation', 'create', 'Add New Organisation'],
    ['organisations', showQuery, 'organisations', 'Organisations', true],
    ['payables', showHTML, 'help/payables.html', 'Payables', false],
    ['purchaseinvoice.list', showQuery, 'purchaseinvoicelist', 'Purchase Invoices', true],
    ['purchaseinvoice.create', showForm, 'purchaseinvoice', 'create', 'New Purchase Invoice'],
    ['purchaseorder.list', showQuery, 'purchaseorders', 'Purchase Orders', true],
    ['purchaseorder.create', showForm, 'purchaseorder', 'create', 'New Purchase Order'],
    ['purchasepayment.create', showForm, 'purchasepayment', 'create', 'Enter Purchase Payment'],
    ['purchasepayments', showQuery, 'purchasepayments', 'Purchase Payments', true],
    ['product.create', showForm, 'product', 'create', 'Add New Product'],
    ['products', showQuery, 'products', 'Products', true],
    ['rpt_accountsreceivable', showQuery, 'reports/accountsreceivable', 'Accounts Receivable', true],
    ['rpt_ageddebtors', showQuery, 'reports/ageddebtors', 'Aged Debtors', false, false],
    ['rpt_balancesheet', showReport, 'rpt_balancesheet'],
    ['rpt_profitandloss', showReport, 'rpt_profitandloss'],
    ['rpt_trialbalance', showQuery, 'reports/trialbalance', 'Trial Balance', false],
    ['rpt_vat', showReport, 'rpt_vat'],
    ['salesinvoices', showQuery, 'salesinvoices', 'Sales Invoices', true],
    ['salesorder.create', showForm, 'salesorder', 'create', 'New Sales Order'],
    ['salesorders', showQuery, 'salesorders', 'Sales Orders', true],
    ['salesorders.process', showForm, 'salesorder', 'process', 'Manual Billing Run'],
    ['salespayment.create', showForm, 'salespayment', 'create', 'Enter Sales Payment'],
    ['salespayments', showQuery, 'salespayments', 'Sales Payments', true],
    ['business.update', showForm, 'business', 'update', 'Business Settings', g_business],
    ['business.create', getForm, 'business', 'create', 'Add New Business'],
    ['businessview', showQuery, 'businesses', 'Businesses', true],
    ['chartadd', showForm, 'account', 'create', 'Add New Account'],
    ['chartview', showQuery, 'accounts', 'Chart of Accounts', true],
    ['journal', setupJournalForm],
    ['ledger', showQuery, 'ledgers', 'General Ledger', true],
    ['logout', logout],
];

/* data sources for each form
 * NB: when populating combos, the XML returned MUST have fields called
 * "id" and "name" - use SQL AS to rename them if necessary
 */

g_formdata = [
    ['bank', 'statement', ['accounts.asset'], ],
    ['bank', 'reconcile', [
        'accounts.unreconciled',
        'accounts',
        'debtors',
        'creditors',
    ], ],
    ['bank', 'reconcile.data', [
        'bank.unreconciled',
        'journal.unreconciled',
    ], ],
    ['bank', 'upload', ['accounts.asset'], ],
    ['journal', 'create', ['accounts', 'divisions', 'departments', 'organisations'], ],
    ['salesorder', 'create', ['organisations', 'cycles', 'products'], ],
    ['salesorder', 'update', ['organisations', 'cycles', 'products'], ],
];

FORMDATA = {
    'account': {
        'create': ['accounttypes'],
        'update': ['accounttypes'],
    },
    'journal': {
        'delete': ['journallines/{id}/'],
    },
    'organisation': {
        'update': ['contactssorted','relationships'],
    },
    'organisation_contact': {
        'update': [],
    },
    'product': {
        'create': ['accounts.revenue'],
        'update': ['accounts.revenue', 'taxes'],
    },
    'purchaseinvoice': {
        'create': ['cycles', 'organisations', 'productcombo_purchase'],
        'update': ['cycles', 'productcombo_purchase', 'purchaseinvoiceitems/{id}/'],
    },
    'purchaseorder': {
        'create': ['cycles', 'organisations', 'productcombo_purchase'],
        'update': ['cycles', 'productcombo_purchase', 'purchaseorderitems/{id}/'],
    },
    'purchasepayment': {
        'create': ['paymenttype', 'organisations', 'accounts.asset'],
        'update': ['paymenttype', 'organisations', 'accounts.asset'],
    },
    'salesorder': {
        'create': ['cycles', 'organisations', 'productcombo'],
        'update': ['cycles', 'productcombo', 'salesorderitems/{id}/'],
    },
    'salespayment': {
        'create': ['paymenttype', 'organisations', 'accounts.asset'],
        'update': ['paymenttype', 'organisations', 'accounts.asset'],
    },
}

MAPFIELDS = {
    'contact': ['line_1', 'line_2', 'line_3', 'town', 'county', 'country',
        'postcode'
    ],
    'organisation': ['line_1', 'line_2', 'line_3', 'town', 'county', 'country',
        'postcode'
    ]
}

var g_max_ledgers_per_journal = 7;
var g_frmLedger;
var g_xml_accounttype = '';
var g_xml_business = ''
var g_xml_relationships = '';
var g_warnlogout = true;

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
    var w = $(this).parents('div.workspace');
    var j = $(this).parents('div.tr.journal:first');
    var newj = j.clone(true, true);
    var o = new Object();
    o.date = mytab.find('div.bank.target div.td.xml-date').text();
    o.description = mytab.find('div.journal input.description').val();
    o.nominal = mytab.find('div.journal select.nominalcode').val();
    o.division = mytab.find('div.journal select.division').val();
    o.department = mytab.find('div.journal select.department').val();
    o.debit = mytab.find('div.journal input.debit').val();
    o.credit = mytab.find('div.journal input.credit').val();

    /* validate */
    if (!bankJournalValidate(o)) {
        return false;
    }

    /* default description to bank entry */
    if (o.description.length == 0) {
        o.description = mytab.find('div.bank.target div.td.xml-description').text();
    }

    j.after(newj);

    bankTotalsUpdate();
}

/* user clicked delete button on entry */
function bankJournalDel() {
    var mytab = activeTab();
    var row = $(this).parents('div.tr');

    if (row.is(':first-child')) {
        /* this is the first row, so just clear it, not delete */
        return false; /* TODO */
    }

    $(this).parents('div.tr').fadeOut(150, function() {
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
    if (o.nominal < 0) {
        return false;
    } /* TODO: report warning to user */
    if (decimalPad(o.debit, 2) == '0.00' && decimalPad(o.credit, 2) == '0.00') {
        return false;
    }
    return true;
}

function bankJournalAmountChange() {
    console.log('bankJournalAmountChange()');
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
    var amount = decimalPad(roundHalfEven(Math.abs($(this).val()), 2), 2);

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
    bankTotalsUpdate();
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
    journal.find('button.del').off().click(bankJournalDel);
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
    var entries = mytab.find('div.bank.journal input.debit');
    target.add(entries).each(function() {
        var debit = '0.00';
        if ($.isNumeric($(this).text())) {
            debit = $(this).text();
        }
        else if ($.isNumeric($(this).val())) {
            debit = $(this).val();
        }
        debits = decimalAdd(debits, debit);
        debits = decimalPad(debits, 2);
        mytab.find('div.bank.total div.xml-debit').text(debits);
        bankTotalsUpdated();
    });
    var target = mytab.find('div.bank.target div.xml-credit');
    var entries = mytab.find('div.bank.journal input.credit');
    target.add(entries).each(function() {
        var credit = '0.00';
        if ($.isNumeric($(this).text())) {
            credit = $(this).text();
        }
        else if ($.isNumeric($(this).val())) {
            credit = $(this).val();
        }
        credits = decimalAdd(credits, credit);
        credits = decimalPad(credits, 2);
        mytab.find('div.bank.total div.xml-credit').text(credits);
        bankTotalsUpdated();
    });
}

/* called any time one of the totals is updated */
function bankTotalsUpdated() {
    console.log('bankTotalsUpdated()');
    var mytab = activeTab();
    var debits = mytab.find('div.bank.total div.xml-debit').text();
    var credits = mytab.find('div.bank.total div.xml-credit').text();
    var totals = mytab.find('div.bank.total div.xml-debit')
        .add(mytab.find('div.bank.total div.xml-credit'));
    var btnsave = mytab.find('div.results.pager button.save');
    if (debits == credits) { /* totals are balanced */
        totals.addClass('balanced');
        btnsave.removeAttr('disabled');
    }
    else { /* totals unbalanced */
        totals.removeClass('balanced');
        btnsave.attr('disabled', 'disabled');
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
    if (offset == undefined) {
        offset = 0;
    }
    if (reverse == undefined) {
        reverse = 'ASC';
    }
    mytab.find('div.results.pager').data('offset', offset)
    mytab.find('div.results.pager').data('reverse', reverse)
    mytab.find('div.results.pager').data('limit', limit);
    var url = 'bank.unreconciled/' + account + '/' + limit + '/' + offset + '/'
        + reverse;
    var d = new Array(); /* array of deferreds */

    bankResultsPager(account, 'reconcile');
    bankJournalReset();
    bankTotalsUpdate();
    bankEntriesClear();

    /* set up save/cancel/delete buttons */
    var btncancel = mytab.find('div.results.pager button.cancel');
    btncancel.off().click(bankReconcileCancel);
    btncancel.removeAttr('disabled');
    var btnsave = mytab.find('div.results.pager button.save');
    btnsave.attr('disabled', 'disabled');
    btnsave.off().click(bankReconcileSave);
    var btndel = mytab.find('div.results.pager button.delete');
    btndel.off().click(bankReconcileDelete);

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
                bankReconcilePresetDebitCredit();
                bankTotalsUpdate();
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

function bankReconcilePresetDebitCredit() {
    console.log('bankReconcilePresetDebitCredit()');
    var mytab = activeTab();
    var debit = mytab.find('div.bank.target div.td.xml-debit').text();
    var credit = mytab.find('div.bank.target div.td.xml-credit').text();
    console.log('debit: ' + debit);
    console.log('credit: ' + credit);
    if ($.isNumeric(debit)) {
        mytab.find('div.bank.workspace input.credit').val(debit);
        mytab.find('select.nominalcode').val('1100')
            .trigger("change")
            .trigger("liszt:updated");
    }
    else if ($.isNumeric(credit)) {
        mytab.find('div.bank.workspace input.debit').val(credit);
        mytab.find('select.nominalcode').val('2100')
            .trigger("change")
            .trigger("liszt:updated");
    }
}

/* delete button clicked */
function bankReconcileDelete() {
    console.log('bankReconcileDelete()');
    if (confirm('Really delete this bank entry?')) {
        console.log('deleting bank entry - user confirmed');
        var mytab = activeTab();
        var id = mytab.find('div.bank.target div.td.xml-id').text();
        var url = collection_url('banks') + id;
        $.ajax({
            url: url,
            type: 'DELETE',
            beforeSend: function(xhr) {
                setAuthHeader(xhr);
            },
            complete: function(xml) {
                bankReconcileNext(mytab);
            }
        });
    }
    else {
        console.log('delete of bank entry cancelled by user');
    }
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

    /* add target from bank statement */
    var t = {};
    t.tab = mytab;
    t.target = '';
    t.id = mytab.find('div.bank.target div.tr div.td.xml-id').text();
    t.date = mytab.find('div.bank.target div.tr div.td.xml-date').text();
    t.desc = mytab.find('div.bank.target div.tr div.td.xml-description')
        .text();
    t.acct = mytab.find('div.bank.target div.tr div.td.xml-account').text();
    t.debit = mytab.find('div.bank.target div.tr div.td.xml-debit').text();
    t.credit = mytab.find('div.bank.target div.tr div.td.xml-credit').text();
    t.amount = (t.debit > 0) ? t.debit : t.credit;
    t.type = (t.debit > 0) ? 'debit' : 'credit';
    t.debtor = mytab.find('select.debtor').val();
    t.creditor = mytab.find('select.creditor').val();

    var xml = createRequestXml();
    xml += '<account>' + t.acct + '</account>';
    xml += '<bank id="' + t.id + '">';
    xml += '<transactdate>' + t.date + '</transactdate>';
    xml += '<description>' + escapeHTML(t.desc) + '</description>';
    xml += '<paymenttype>1</paymenttype>'; /* FIXME: hardcoded */

    /* debit/credit */
    xml += '<' + t.type + '>' + t.amount + '</' + t.type + '>';

    var supp = '';

    /* process Debtors and Creditors */
    t.tab.find('div.bank.journal.tr').each(function() {
        var nominalcode = $(this).find('select.nominalcode').val();
        if (nominalcode === '1100' || nominalcode === '2100') {
            var s = (t.type === 'debit') ? 'debtor' : 'creditor';
            var op = (t.type === 'debit') ? 'credit' : 'debit';
            var org = $(this).find('select.' + s).val();
            var amount = $(this).find('input.' + op).val();
            xml += '<payment>';
            xml += '<organisation>' + org + '</organisation>';
            xml += '<amount>' + amount + '</amount>';
            xml += '<description>' + escapeHTML(t.desc) + '</description>';
            /* payment allocations */
            t.tab.find('div.bank.suspects div.tr.selected').each(function() {
                xml += '<paymentallocation>';
                var invoice = $(this).find('div.xml-id').text();
                var allocate = $(this).find('input.allocate').val();
                xml += '<invoice>' + invoice + '</invoice>';
                xml += '<amount>' + allocate + '</amount>';
                xml += '</paymentallocation>';
            });
            xml += '</payment>';
        }
        else {
            var op = (t.type === 'debit') ? 'credit' : 'debit';
            var amount = $(this).find('input.' + op).val();
            supp += '<ledger>';
            supp += '<account>' + nominalcode + '</account>';
            /* TODO: division & department hardcoded */
            //supp += '<division>' + '1' + '</division>';
            //supp += '<department>' + '1' + '</department>';
            supp += '<' + op + '>' + amount + '</' + op + '>';
            supp += '</ledger>';
        }
    });

    /* process supplimentary journals */
    xml += supp;


    xml += '</bank></data></request>';
    t.request = xml;
    t.url = collection_url('banks');
    bankReconcilePost(t);
}

function bankReconcileSuggest() {
    console.log('bankReconcileSuggest()');
    var d = new Array();
    var id = undefined;
    TABS.active.tablet.find('div.td.debtorcreditor').each(function() {
        /* display unpaid PI/SI for debtor/creditor account(s) selected */
        if ($(this).find('div.td.debtor').is(':visible')) {
            console.log('finding SIs');
            id = $(this).parents('div.tr').find('select.debtor').val();
            d.push(getHTML(collection_url('salesinvoice.suggestions/' + id)));
        }
        if ($(this).find('div.td.creditor').is(':visible')) {
            console.log('finding PIs');
            id = $(this).parents('div.tr').find('select.creditor').val();
            d.push(getHTML(collection_url('purchaseinvoice.suggestions/' + id)));
        }
    });
    $.when.apply(null, d)
        .done(function(html) {
            var docs = Array.prototype.splice.call(arguments, 0);
            bankSuggestResults(docs);
        });
    return d;

}

function businessPeriodStart() {
    var business = $(g_xml_business).find('id').filter(function() {
        return $(this).text() === g_business;
    }).parent();
    var period_start = business.find('period_start').text();
    return period_start;
}

function createJournalEntry(t) {
    console.log('createJournalEntry()');
    var xml = createRequestXml();
    xml += '<journal transactdate="' + t.date + '" description="';
    xml += escapeHTML(t.desc);
    xml += '">';

    /* our xsd schema requires debits to appear before credits */
    if (t.debit > 0) {
        xml += '<debit account="' + t.acct + '" amount="' + t.amount + '" ';
        xml += 'bankid="' + t.id + '"/>';
    }
    else {
        t.target = '<credit account="' + t.acct + '" amount="' + t.amount + '" ';
        t.target += 'bankid="' + t.id + '"/>';
    }

    /* add debits */
    t.tab.find('div.bank.journal.tr').each(function() {
        var amount = $(this).find('div.td.xml-debit input').val();
        if (amount > 0) {
            xml += '<debit account="' + t.acct + '" amount="' + amount + '"/>';
        }
    });

    /* add credits */
    t.tab.find('div.bank.journal.tr').each(function() {
        var amount = $(this).find('div.td.xml-credit input').val();
        if (amount > 0) {
            xml += '<credit account="' + t.acct + '" amount="' + amount + '"/>';
        }
    });
    xml += t.target;
    xml += '</journal></data></request>';
    t.request = xml;
    t.url = collection_url('journals');
    bankReconcilePost(t);
}

/* POST journal */
function bankReconcilePost(t) {
    showSpinner('Saving...');
    $.ajax({
        url: t.url,
        data: t.request,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(xml) {
            t.response = xml;
            bankReconcileNext(t);
        },
        error: function(xml) {
            hideSpinner();
            statusMessage('Error reconciling transaction', STATUS_CRIT);
        }
    });
}

/* clean up, move on */
function bankReconcileNext(t) {
    hideSpinner();
    statusMessage('Saved.', STATUS_INFO, 5000);
    bankReconcileCancel();
    bankResultsPagerAction(t.acct, 'reconcile');
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
        if (offset < 0) {
            offset = 0
        };
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
        if (offset < 0) {
            offset = 0
        };
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
    var limit = Math.floor((hbox - hhead) / hrow) - 2;

    /* set defaults */
    if (offset == undefined) {
        offset = 0;
    }
    if (order == undefined) {
        order = 'ASC';
    }
    if (reverse == undefined) {
        reverse = 'ASC';
    }
    if (sortfield == undefined) {
        sortfield = 'date';
    }

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
        mytab.find('div.pager button.unreconcile').attr('disabled', 'disabled');
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

function bankSuggestResults(docs) {
    console.log('bankSuggestResults()')
    var results = 0;
    var rows = 0;
    var mytab = activeTab();
    var workspace = mytab.find('div.bank.suspects');
    var html = undefined;
    workspace.empty();
    if (Object.prototype.toString.call(docs[0]) !== '[object Array]') {
        docs = [docs]; /* force into array */
    }
    console.log(docs.length + ' doc(s) returned.');
    for (var i = 0; i < docs.length; i++) {
        html = docs[i][0];
        rows = $(html).find('div.bank.suggestion').length;
        results += rows;
        console.log(rows + ' rows(s) found.');
        if (rows > 0) {
            /* suggestions found, show them */
            workspace.append(html);
            console.log('appending ' + rows + ' row(s)');
        }
    }
    workspace.find('div.bank.suggestion').off().click(bankSuggestionClick);
    workspace.find('div.bank.suggestion input.allocate').off()
        .click(bankAllocateClick)
        .change(bankAllocateChange);
}

function bankAllocateClick(event) {
    event.stopPropagation(); /* prevent bankSuggestionClick() */
}

function bankAllocateChange(event) {
    /* validate amount */
    var mytab = activeTab();
    var debit = mytab.find('div.bank.target div.td.xml-debit').text();
    var credit = mytab.find('div.bank.target div.td.xml-debit').text();
    var max = (debit === '') ? credit : debit;
    var newval = $(this).val();
    var sitotal = $(this).parents('div.tr').find('div.td.xml-total').text();

    var allocated = '0.00';
    mytab.find('div.bank.suggestion input.allocate').each(function() {
        if (!isNaN($(this).val())) {
            if (Number($(this).val()) > Number('0.00')) {
                allocated = decimalAdd(allocated, $(this).val());
            }
        }
    });
    max = decimalSubtract(max, allocated);

    /* Ensure amount allocated is not more than the amount paid */
    if (Number(newval) > Number(max)) {
        newval = max;
    }

    /* Ensure amount allocated is not more than invoice total */
    if (Number(newval) > Number(sitotal)) {
        newval = sitotal;
    }

    /* Bankers rounding */
    newval = roundHalfEven(newval, 2);

    /* 2 Decimal Places */
    newval = decimalPad(newval, 2);

    $(this).val(newval);
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

    var allocated = '0.00';
    mytab.find('div.bank.suggestion input.allocate').each(function() {
        if (!isNaN($(this).val())) {
            if (Number($(this).val()) > Number('0.00')) {
                allocated = decimalAdd(allocated, $(this).val());
            }
        }
    });
    console.log('allocated: ' + allocated);

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
            var sitotal = $(this).find('div.td.xml-total').text();
            var org = $(this).find('div.td.xml-organisation').first().text();
            var unallocated = decimalSubtract(amount, allocated);

            /* start assuming we will allocate the full amount available */
            var total = unallocated;

            /* don't allocate more than the amount of the invoice */
            if (Number(sitotal) < Number(unallocated)) {
                total = sitotal;
                console.log(' rule #1');
            }
            /* don't allocate more than we have left */
            if (Number(unallocated) < Number(total)) {
                total = unallocated;
                console.log(' rule #2');
            }

            /* format nicely */
            total = decimalPad(total, 2);

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

            /* fill in allocation amount */
            row.find('input.allocate').val(total);
        }
        else {
            /* SI unselected - remove from div.entries */
            mytab.find('div.entries div.tr.salesinvoice div.td.xml-id')
                .each(function() {
                    if ($(this).text() == id) {
                        $(this).parents('div.tr.salesinvoice').remove();
                    }
                });

            /* clear allocation amount */
            row.find('input.allocate').val('');
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
            console.log('decimalSubtract(' + overpay + ',' + sitotal + ')');
            overpay = decimalPad(decimalSubtract(overpay, sitotal), 2);
        });

    /* append overpayment if required */
    mytab.find('div.bank.entries div.overpayment').remove();
    if (Number(overpay) > 0) {
        console.log('Overpayment: ' + overpay);
        /* overpayment - post to suspense account (9999) */
        var dctl = $('<div class="tr salesinvoice overpayment"/>');
        dctl.append('<div class="td xml-id">' + id + '</div>');
        dctl.append('<div class="td xml-organisation">' + org + '</div>');
        dctl.append('<div class="td xml-date">' + date + '</div>');
        dctl.append('<div class="td xml-description">Unallocated</div>');
        dctl.append('<div class="td xml-account">9999</div>');
        dctl.append('<div class="td xml-debit"/>');
        dctl.append('<div class="td xml-credit">' + overpay + '</div>');
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
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
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
    console.log('Reconciling bank entry ' + bank + ' against ledger ' + ledger);

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
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
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
    xml += '<bank id="' + id + '" unreconcile="true">';
    xml += '</bank></data></request>';

    showSpinner('Unreconciling bank item ' + id + '...');
    $.ajax({
        url: collection_url('banks') + id,
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
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

function collectionObjectCustom(collection) {
    if (collection === 'purchaseinvoices') {
        return 'purchaseinvoice';
    }
    if (collection === 'salesinvoices') {
        return 'salesinvoice';
    }
    return ''
}

function nominalAccountChange() {
    console.log('nominalAccountChange()');
    var w = $(this).parents('div.bank.workspace div.tr');
    if ($(this).val() === '1100') {
        console.log('Debtors Control');
        w.find('div.debtor').show();
        w.find('div.creditor').hide();
    }
    else if ($(this).val() === '2100') {
        console.log('Creditors Control');
        w.find('div.debtor').hide();
        w.find('div.creditor').show();
    }
    else {
        w.find('div.debtor').hide();
        w.find('div.creditor').hide();
    }
    /* reset debtor/creditor combos */
    w.find('div.debtorcreditor select').each(function() {
        $(this).val(-1);
    });
}

/* override gladd.js function
 * deprecated - use Form.prototype.eventsCustom() instead */
customFormEvents = function(tab, object, action, id) {
    console.log('customFormEvents().gladbooks');
    var mytab = getTabById(tab);

    /* remove scrollbar from tablet - we'll handle this in the bank.data div */
    if (object == 'bank') mytab.addClass('noscroll');

    /* upload button click handler */
    mytab.find('button.upload').click(function() {
        uploadFile(csvToXml, '/fileupload/' + g_instance + '/');
    });

    mytab.find('select.bankaccount').change(bankChange);

    /* onChange event for account dropdown */
    mytab.find('select.nominalcode').change(nominalAccountChange);

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
    if ((object === 'contact' || object === 'organisation') 
            && action === 'update')
    {
        var addressFields = ['line_1', 'line_2', 'line_3', 'town', 'county',
            'country', 'postcode'
        ];
        var selector = addressFields.join('"],input[name="');
        selector = 'input[name="' + selector + '"]';
        mytab.find(selector).change(mapUpdate);
    }

    if (object === 'journal') {
        customFormEventsJournal(tab, object, action, id, mytab);
    }

    /* organisation.update addrow button */
    if (object == 'organisation' && action == 'update') {
        mytab.find('button.addrow').click(function() {
            console.log('organisation.update.addrow()');
            addSubformEvent($(this), "organisation_contacts", id, tab);
        });
    }

    if (object === 'salesorder') {
        customFormEventsSalesOrder(tab, object, action, id, mytab);
    }
}

function customFormEventsJournal(tab, object, action, id, mytab) {
    var reverseid = mytab.find('input[name="reverseid"]').val();
    if (!($.isNumeric(reverseid))) {
        mytab.find('button.save').removeClass('hidden');
    }
}

function customFormEventsSalesOrder(tab, object, action, id, mytab) {
    mytab.find('select[name="cycle"]').change(function() {
        console.log('salesorder.cycle changed');
        var start_date = mytab.find('div.start_date');
        var end_date = mytab.find('div.end_date');
        var cycle = $(this).find('option:selected').text();
        if (cycle === 'never') {
            start_date.addClass('hidden');
        }
        else {
            start_date.removeClass('hidden');
        }
        if (cycle === 'never' || cycle === 'once') {
            end_date.addClass('hidden');
        }
        else {
            end_date.removeClass('hidden');
        }
    });
}


customBusinessNotFound = function(xml) {
    console.log('Create first business');
    $('nav.site').hide();
    $('div.tabheaders').addClass('invisible');
    $('div.navbar-search').hide();
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
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
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
    transactdate.datepicker("setDate", currentDate);

    /* set up click() events */
    $('button#journalsubmit').click(function(event) {
        submitJournalEntry(event, jf);
    });

    /* set up blur() events */
    $('div.tablet.active.business' + g_business).find('input.amount').each(function() {
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

function objectCollectionCustom(object) {
    if (object === 'business') {
        return 'businesses';
    }
    return object + 's';
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
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
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
}

function productBoxClone(mytab, product) {
    var productBox = $('<td class="xml-product"></td>');
    var productCombo = mytab.find('select.product.nosubmit').clone(true);
    productCombo.removeAttr("id");
    productCombo.css({
        display: "inline-block"
    });
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
    combo.css({
        display: "inline-block"
    });
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
            for (var x = 0; x < combo[0].options.length; x++) {
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

function salesorderAddProduct(tab, datatable, id, product, linetext, price, qty) {
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
    row.find('button.removerow').click(function() {
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
        termstring += '<term type="numeric">'
            + terms.numbers.join('</term><term type="numeric">') + '</term>';
    }
    if (terms.dates.length > 0 && terms.dates[0] != '') {
        termstring += '<term type="date">'
            + terms.dates.join('</term><term type="date">') + '</term>';
    }
    /* do not attempt search without any search terms */
    if (termstring.length == 0) {
        return;
    }

    $(doc).find('request').prepend('<business>' + g_business + '</business>');
    $(doc).find('request').prepend('<instance>' + g_instance + '</instance>');
    $(doc).find('search').prepend(termstring);
    var xml = flattenXml(doc);
    $.ajax({
        url: collection_url('search'),
        type: 'POST',
        data: xml,
        contentType: 'text/xml',
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(html) {
            console.log('search complete');
            if (html == '(null)') {
                return;
            }
            html = html.replace(/&lt;div([^&]+)&gt;/g, '<div$1>');
            html = html.replace('&lt;/div&gt;', '</div>', 'g');
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
    if ($(this).hasClass('ledger')) {
        var journal = $(this).find('div.td.journal').text();
        console.log('ledger #' + id + ' => journal #' + journal);
        showForm('journal', 'delete', 'Journal #' + journal, journal);
    }
    if ($(this).hasClass('organisation')) {
        console.log('organisation ' + id);
        var name = $(this).find('div.td.name').text();
        showForm('organisation', 'update', name, id);
    }
    if ($(this).hasClass('product')) {
        console.log('product ' + id);
        var name = $(this).find('div.td.shortname').text();
        showForm('product', 'update', name, id);
    }
    if ($(this).hasClass('salesinvoice')) {
        console.log('salesinvoice ' + id);
        var ref = $(this).find('div.td.ref').text();
        var si = 'SI-' + ref.replace('/', '-') + '.pdf';
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
    for (var i = z; i < terms.words.length; i++) {
        /* split the word down further and add these as extra search terms */
        if (isDate(terms.words[i])) {
            /* date - move to terms.dates */
            terms.dates.push(terms.words[i]);
            terms.words.splice(i, 1);
        }
        else if (isNaN(terms.words[i])) { /* don't split numbers */
            var tok = terms.words[i].split(/[\W]+/);
            if (tok.length > 1) {
                for (var j = 0; j < tok.length; j++) {
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
    if (terms.words.length == 1 && terms.words[0] == '') {
        return null;
    }
    return terms;
}

function setupJournalForm(tab) {

    /* load dropdown contents */
    $.ajax({
        url: collection_url('divisions'),
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(xml) {
            populateDivisionsDDowns(xml, tab);
        }
    });

    $.ajax({
        url: collection_url('departments'),
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(xml) {
            populateDepartmentsDDowns(xml, tab);
        }
    });

    $.ajax({
        url: collection_url('accounts'),
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(xml) {
            populateAccountsDDowns(xml, tab);
        }
    });

    populateDebitCreditDDowns();
}

function showReport(report) {
    if (report === 'rpt_balancesheet') {
        var title = 'Balance Sheet'; /* TODO: i18n */
    }
    else if (report === 'rpt_profitandloss') {
        var title = 'Profit & Loss'; /* TODO: i18n */
    }
    else if (report === 'rpt_vat') {
        var title = 'VAT Report';   /* TODO: i18n */
    }
    var form = showForm('report', 'update', title, false);
    form.classes.push(report);
    form.d.done(function() {
        start_date = form.tab.find('input[name="start_date"]');
        end_date = form.tab.find('input[name="end_date"]');
        if (report === 'rpt_balancesheet') {
            if (!isDate(start_date)) {
                start_date.datepicker('setDate', new Date());
                start_date.trigger('change');
            }
        }
        else if (report === 'rpt_profitandloss') {
            var period_start = businessPeriodStart();
            if (!isDate(start_date) && isDate(period_start)) {
                start_date.datepicker('setDate', new Date(period_start));
                start_date.trigger('change');
            }
            if (!isDate(end_date)) {
                end_date.datepicker('setDate', new Date());
                end_date.trigger('change');
            }
        }
    });
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
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(xml) {
            console.log('success');
            if (bankid) {
                activeTab().find('select.bankaccount').change();
            }
            else {
                submitJournalEntrySuccess(xml, form);
            }
        },
        error: function(xml) {
            submitJournalEntryError(xml);
        }
    });
}

/* override the gladd.js function which sets tab titles */
tabTitle = function(title, object, action, xml) {
    var namedobjects = ['account', 'contact', 'department', 'division',
        'organisation', 'product', 'purchaseorder', 'salesorder'
    ];

    if (namedobjects.indexOf(object) != -1 && action == 'update' && xml[0]) {
        if (object == 'account') {
            var id = $(xml[0]).find('id').first().text();
            var desc = $(xml[0]).find('description').first().text();
            title = id + ' - ' + desc;
        }
        else if (object == 'product') {
            title = $(xml[0]).find('shortname').first().text();
        }
        else if (object == 'purchaseorder') {
            title = 'PO/' + $(xml[0]).find('order').first().text();
        }
        else if (object == 'salesorder') {
            title = 'SO/' + $(xml[0]).find('order').first().text();
        }
        else {
            title = $(xml[0]).find('name').first().text();
        }
    }
    return title;
}

function updateSalesOrderTotals(tab) {
    /* FIXME: uncaught exception: NaN */
    console.log('Updating salesorder totals');

    var subtotal = Big('0.00');
    var taxes = Big('0.00');
    var gtotal = Big('0.00');
    var mytab = getTabById(tab);
    var x = 0;

    mytab.find('input.total:not(.clone)').each(function() {
        /* get line total, stripping commas */
        x = $(this).val().replace(',', '');
        if ((!isNaN(x)) && (x != '')) {
            subtotal = subtotal.plus(Big(x));
        }
    });

    gtotal = subtotal.plus(taxes);

    /* update sub total */
    subtotal = decimalPad(subtotal, 2);
    mytab.find('table.totals').find('td.subtotal').each(function() {
        $(this).text(formatThousands(subtotal));
    });

    /* update grand total */
    gtotal = decimalPad(gtotal, 2);
    mytab.find('table.totals').find('td.gtotal').each(function() {
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
    if (action === 'create') {
        type.addClass('dirty'); /* ensure we submit type */
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

function validateFormSalesPayment(action, id) {
    var mytab = activeTab();
    var type = mytab.find('select[name="paymenttype"] option:selected').text();
    var desc = mytab.find('input[name="description"]');
    desc.val(type);
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
            xml += 'transactdate="' + $(form).find('.transactdate').val() + '" ';
            if (bankid) xml += 'bankid="' + bankid + '" ';
            xml += 'description="' + escapeHTML($(this).val().trim()) + '">';
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
    console.log('Nominal code is within acceptable range');

    return true;
}

function customBlurEvents(tab) {
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
    else if (['debtor', 'creditor'].indexOf(combo.attr('name')) !== -1) {
        return bankReconcileSuggest();
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
        switchBusiness(g_business);
        $('nav.site').show();
        $('div.tabheaders').removeClass('invisible');
        $('div.navbar-search').show();
        hideSpinner();
        return false;
    }
    if (object === 'contact' && action === 'create') {
        /* organisation_contact htmlpane */
        var tab = TABS.active;
        var t = tab.tablet;
        t.find('div.organisation_contact.create input').val('');
        if (tab.form !== undefined) tab.form._populateHTMLPanes();
        return false;
    }
    return true;
}

customClickElement = function(row) {
    console.log('customClickElement()');
    var tab = TABS.active;
    var action = 'update';

    /* Some collections should never do anything when clicked */
    var inert = ['purchasepayments', 'salespayments'];
    if (inert.indexOf(tab.collection) != -1) {
        return true;
    }

    if (['accounts', 'contacts', 'divisions', 'departments', 'organisations']
        .indexOf(tab.collection) !== -1) {
        var id = row.find('td.xml-id').text();
        var name = row.find('td.xml-name').text();
        var object = tab.collection.substr(0, tab.collection.length - 1);
        showForm(object, action, name, id);
        return true;
    }
    else if (tab.collection === 'ledgers') {
        /* display whole journal, not just one ledger */
        var id = row.find('td.xml-journal').text();
        showForm('journal', 'delete', 'Journal #' + id, id);
        return true;
    }
    else if (tab.collection == 'products') {
        var id = row.find('td.xml-id').text();
        var name = row.find('td.xml-shortname').text();
        showForm('product', 'update', name, id);
        return true;
    }
    else if (tab.collection == 'purchaseinvoicelist') {
        var id = row.find('td.xml-id').text();
        var name = 'Purchase Invoice #' + id;
        showForm('purchaseinvoice', 'update', name, id);
        return true;
    }
    else if (tab.collection == 'purchaseorders') {
        var id = row.find('td.xml-id').text();
        var name = 'PO/' + row.find('td.xml-order').text();
        showForm('purchaseorder', 'update', name, id);
        return true;
    }
    else if (tab.collection == 'salesorders') {
        var id = row.find('td.xml-id').text();
        var name = 'SO/' + row.find('td.xml-order').text();
        showForm('salesorder', 'update', name, id);
        return true;
    }
    else if (tab.collection == 'salesinvoices') {
        /* view salesinvoice pdf */
        var a = row.find('td.xml-pdf').find('a');
        var href = a.attr('href');
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
        else if (tab.collection === 'reports/ageddebtors') {
            var id = row.find('td.xml-id').text();
            var name = row.find('td.xml-customer').text();
            showForm('organisation', 'update', name, id);
            return true;
        }
        else {
            var title = null;
        }
        displayElement(tab.collection, id, title);
        return true;
    }
}

Form.prototype.addOrganisationContact = function() {
    console.log('Form.prototype.addOrganisationContact()');
    var t = this.tab.tablet;
    var object = 'contact';
    var action = 'create';
    var collection = object + 's';
    var url = collection_url(collection);
    var form = t.find('div.organisation_contact.create');
    var xml = formToXML(form, object, action);
    xml = $.parseXML(xml);
    /* FIXME: pull types from combo */
    var rels = '<relationship organisation="' + this.id + '" type="0" />';
    $(xml).find(object).append(rels);
    xml = flattenXml(xml);
    console.log(xml);
    postXML(url, xml, object, action);
}

Form.prototype.customXML = function() {
    var xml = $.parseXML(this.xml);
    if (this.object === 'product' && this.action === 'create') {
        /* apply Standard Rate VAT by default to new products */
        $(xml).find(this.object).append('<tax>1</tax>');
    }
    else if (this.object === 'purchaseinvoice' && !this.draft) {
        /* not a draft, so tell api to post the journal */
        $(xml).find(this.object).attr('post', true);
    }
    this.xml = flattenXml(xml);
}

Form.prototype.delOrganisationContact = function(id) {
    console.log('Form.prototype.delOrganisationContact(' + id +  ')');
    var collection = 'organisation_contacts/' + this.id + '/' + id + '/';
    var url = collection_url(collection);
    var form = this;

    $.ajax({
        url: url,
        method: 'DELETE',
        dataType: 'html',
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(html) {
            form._populateHTMLPanes();
        },
        error: function() {
            console.log('error loading ' + url);
        }
    });
}

Form.prototype.eventsCustom = function() {
    var form = this;
    var t = this.tab.tablet;
    if (this.object === 'contact' && this.action === 'update') {
        t.find('select.actions').off('change').change(function() {
            if ($(this).val() === 'DELETE') {
                if (form.submitDelete()) {
                    form.tab.close();
                }
                else {
                    $(this).val('-1');
                }
            }
        });
    }
    else if (this.object === 'journal') {
        t.find('input[name="reverseid"]').off('click').click(function() {
            var id = $(this).val();
            showForm('journal', 'delete', 'Journal #' + id, id);
        });
    }
    else if (this.object === 'organisation' && this.action === 'update') {

        var c = t.find('div.organisation_contact.create button.addcontact');
        c.off('click').click(function() {
            form.addOrganisationContact();
        });

        c = t.find('div.organisation_contact button.removecontact');
        c.off('click').click(function() {
            var contacts =
                t.find('div.organisation_contact.update input[type="checkbox"]')
                .filter(':checked');
            console.log('contacts selected: ' + contacts.length);
            contacts.each(function() {
                var id = $(this).closest('div.tr').find('input[name="id"]').val();
                form.delOrganisationContact(id);
            });
        });

        c = t.find('div.organisation_contact.create input[name="selectall"]');
        c.off('change').change(function() {
            t.find('div.organisation_contact.update input[type="checkbox"]')
            .prop('checked', c.prop("checked"));
        });

        t.find('div.organisation_contact.update div.xml-name').click(function(){
            var row = $(this).closest('div.tr');
            var id = row.find('input[name="id"]').val();
            var name = $(this).text();
            console.log("showForm('contact', 'update', " + name + ", " + id + ")");
            showForm('contact', 'update', name, id);
        });

        c = t.find('div.organisation_contact.update select.relationship.chozify');
        c.chosen().change(function() {
            var row = $(this).closest('div.tr');
            var id = row.find('input[name="id"]').val();
            form.relationshipUpdate(form.id, id, $(this).val(), false);
        });

        c = t.find('div.organisation_statement div.tr');
        c.off('click').click(function() {
            var type = $(this).find('input[name="type"]').val();
            if (type === 'SI') {
                var ref = $(this).find('input[name="ref"]').val();
                var si = 'SI-' + ref.replace('/', '-') + '.pdf';
                var url = '/pdf/' + g_orgcode + '/' + si;
                window.open(url);
            }
            else if (type === 'SP') {
                form.eventsCustomOrganisationSalesPayment($(this));
            }
        });
    }
    else if (this.object === 'purchaseinvoice') {
        form.draft = true;
        t.find('button.post').off('click').click(function() {
            if (form.validate()) {
                form.draft = false;
                form.submit(true);
            }
        });
    }
    else if (this.object === 'report') {
        this.eventsCustomReport(form, t);
    }
    else if (this.object === 'salesorder' && this.action === 'process') {
        t.find('button.post').off('click').click(function() {
            if (form.validate()) {
                form.submit(true);
            }
        });
    }
}

Form.prototype.eventsCustomOrganisationSalesPayment = function(sp) {
    var form = this;
    var t = this.tab.tablet;
    var id = sp.find('input[name="id"]').val();
    var org = sp.find('input[name="org"]').val();
    var w = sp.closest('div.tabworkspace');
    var pop = w.find('div.popup');
    var row = sp.clone();
    sp.closest('div.organisation_statement').find('div.tr')
        .removeClass('selected');
    sp.addClass('selected');
    var popt = pop.find('div.poptitle');
    var pops = pop.find('div.popselection');
    var popr = pop.find('div.popresults');
    var popf = pop.find('div.popfooter');
    popt.empty().append('Allocate Payment');
    pops.empty().append(row);
    pop.show();
    
    var url = collection_url('salespayment.suggestions' + '/' + org + '/' + id);
    showHTML(url, '', popr)
    .done(function() {
        popr.find('div.tr.salesinvoice input.allocate').each(function() {
            if ($(this).val() !== '0.00') {
                $(this).closest('div.tr').addClass('selected');
            }
        });
        popr.find('div.tr.salesinvoice input.allocate').click(function() {
            return false; // do nothing
        })
        .blur(function() {
            if ($(this).val() === '0.00') {
                $(this).closest('div.tr.salesinvoice').removeClass('selected');
            }
        })
        .change(function() {
            $(this).val(decimalPad($(this).val(), 2));
            if ($(this).val() === '0.00') {
                $(this).closest('div.tr.salesinvoice').removeClass('selected');
            }
        });
        popr.find('div.tr.salesinvoice').off('click').click(function() {
            var allocate = $(this).find('input.allocate');
            var total = $(this).find('div.xml-total').text();
            var paid = $(this).find('div.xml-paid').text();
            var unpaid = new Big(decimalSubtract(total, paid));
            $(this).toggleClass('selected');
            if ($(this).hasClass('selected')) {
                /* allocate the maximum available */
                var max = pops.find('div.xml-credit').text();
                popr.find('input.allocate').each(function() {
                    var v = decimalPad($(this).val(), 2);
                    max = decimalSubtract(max, v);
                });
                var maxB = new Big(max);
                if (maxB.gt(unpaid)) {
                    allocate.val(decimalPad(unpaid, 2));
                }
                else {
                    allocate.val(decimalPad(max, 2));
                }
            }
            else {
                allocate.val('0.00');
            }
            allocate.focus().select();
        });
        popf.find('button.allocate').off('click').click(function() {
            console.log('button.allocate');
            form.eventsCustomOrganisationSalesPaymentAllocate(sp);
        });
    });
}

Form.prototype.eventsCustomOrganisationSalesPaymentAllocate = function(sp) {
    var form = this;
    var w = sp.closest('div.tabworkspace');
    var pop = w.find('div.popup');
    var pops = pop.find('div.popselection');
    var popr = pop.find('div.popresults');
    var salespayment = pops.find('input[name="id"]').val();
    console.log('allocating payment ' + salespayment);
    var salesinvoices = popr.find('div.tr.salesinvoice');
    var xml = createRequestXml();
    xml += '<salespayment>' + salespayment + '</salespayment>';
    var c = 0;
    salesinvoices.each(function() {
        var amount = $(this).find('input.allocate').val();
        var salesinvoice = $(this).find('div.xml-id').text();
        amount = decimalPad(amount,2);
        if (amount !== '0.00') {
            console.log('allocating ' + amount + ' to SI #' + salesinvoice);
            c++;
            xml += '<salespaymentallocation>';
            xml += '<salesinvoice>' + salesinvoice + '</salesinvoice>';
            xml += '<amount>' + amount + '</amount>';
            xml += '</salespaymentallocation>';
        }
    });
    console.log(c + ' invoice(s) allocated');
    xml += '</data></request>';
    var url = collection_url('salespaymentreallocations');
    statusHide();
    showSpinner('Saving...');
    return $.ajax({
        url: url,
        type: 'POST',
        data: xml,
        contentType: 'text/xml',
        timeout: g_timeout,
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(xml) {
            hideSpinner();
            pop.hide();
            sp.removeClass('selected');
        },
        error: function(xhr, s, err) {
            hideSpinner();
            var xml = xhr.responseXML;
            var responsecode = $(xml).find('responsecode').text();
            var responsetext = $(xml).find('responsetext').text();
            if (responsetext) {
                err = responsetext;
            }
            statusMessage('Error: ' + responsetext, STATUS_CRIT);
        }
    });
}

Form.prototype.eventsCustomReport = function(form, t) {
    t.find('input.datefield').change(function() {
        var target = t.find('div.report.update');
        var start_date = t.find('input[name="start_date"]').val();
        var end_date = t.find('input[name="end_date"]').val();
        if (t.hasClass('rpt_balancesheet')) {
            var report = 'reports/balancesheet';
        }
        else if (t.hasClass('rpt_profitandloss')) {
            var report = 'reports/profitandloss';
        }
        else if (t.hasClass('rpt_vat')) {
            var report = 'vatreport';
        }
        if (isDate(start_date) && isDate(end_date)) {
            if (start_date > end_date) {
                statusMessage('From must be before To', STATUS_WARN);
                return false;
            }
            var collection = report + '/' + start_date + '/' + end_date;
            if (t.hasClass('rpt_profitandloss')) {
                showHTML(collection, form.tab.title, target, collection);
            }
            else {
                showQuery(collection, form.tab.title, form.tab.sort, target);
            }
        }
        else if (isDate(start_date) && t.hasClass('rpt_balancesheet')) {
            var collection = report + '/' + start_date;
            showHTML(collection, form.tab.title, target, collection);
        }
    });
}

Form.prototype.onChangeCustom = function(ctl) {
    if (this.object === 'purchaseinvoice') {
        this.onChangeCustomPurchaseInvoice(ctl);
    }
}

Form.prototype.onChangeCustomPurchaseInvoice = function(ctl) {
    console.log('Form.onChangeCustomPurchaseInvoice()');
    var t = this.tab.tablet;
    var xml = createRequestXml();
    var products = t.find('select.product');
    products.each(function() {
        var p = $(this).val();
        var t = $(this).closest('div.tr').find('input.total').val();
        if (p > 0) {
            xml += '<line product="' + p + '" total="' + t + '"/>';
        }
    });
    xml += '</data></request>';
    
    var url = collection_url('calcproducttaxes');

    $.ajax({
        url: url,
        data: xml,
        contentType: 'text/xml',
        type: 'POST',
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        success: function(data) {
            console.log('calc complete');
            var tax = new Big('0.00');
            tax.DP = 2;
            tax.RM = 2; // ROUND_HALF_EVEN
            $(data).find('row').each(function() {
                var rate = $(this).find('rate').text();
                var amount = $(this).find('amount').text();
                if (rate !== undefined && amount !== undefined) {
                    rate = new Big(rate).div(100);
                    amount = new Big(amount);
                    tax = tax.plus(rate.times(amount));
                }
            });
            var taxbox = t.find('input.tax');
            /* update tax, unless user has overridden it */
            if (!taxbox.hasClass('userdefined')) {
                t.find('input.tax').val(tax.toFixed(2)).addClass('dirty');
            }
            var subtotal = t.find('div.tr.totals input.subtotal[type="hidden"]').val();
            subtotal = new Big(subtotal);
            var total = subtotal.plus(tax);
            total.DP = 2;
            total.RM = 2; // ROUND_HALF_EVEN
            t.find('div.tr.totals input.total[type="hidden"]').val(total.toFixed(2)).addClass('dirty');
            t.find('div.tr.totals input.total.nosubmit').val(total.toFixed(2).formatCurrency());
            t.find('div.tr.totals input.subtotal[type="hidden"]').addClass('dirty');
        }
    });
}

Form.prototype.onKeyPressCustom = function(e, ctl) {
    /* set end_date based on start_date */
    if (ctl.attr('name') === 'end_date' && e.which === 43) {
        /* user pressed '+' key */
        var advance = ctl.val();
        var start_date = ctl.closest('div.tr')
            .find('input[name="start_date"]').val();
        if (start_date !== undefined) {
            if ($.isNumeric(advance) && isDate(start_date)) {
                advance = parseInt(advance);
                var d = moment(start_date).add(advance, 'days');
                ctl.val(d.format('YYYY-MM-DD'));
            }
        }
    }
    /* set due date based on taxpoint */
    if (ctl.attr('name') === 'due' && e.which === 43) {
        /* user pressed '+' key */
        var advance = ctl.val();
        var start_date = ctl.closest('div.tr')
            .find('input[name="taxpoint"]').val();
        if (start_date !== undefined) {
            if ($.isNumeric(advance) && isDate(start_date)) {
                advance = parseInt(advance);
                var d = moment(start_date).add(advance, 'days');
                ctl.val(d.format('YYYY-MM-DD'));
            }
        }
    }
}

/* override object variables etc. */
Form.prototype.overrides = function() {
    var t = this.tab.tablet;
    if (this.object === 'journal') {
        this.prompts['delete'] = 'Reverse this journal?';
        this.prompts['deletestatus'] = 'Reversing journal...';
    }
    else if (this.object === 'organisation' && this.action === 'update') {
        /* fill in totals for organisation statement */
        var total = '0.00';
        t.find('div.organisation_statement div.tr').each(function() {
            $(this).find('div.xml-debit').each(function() {
                debit = $(this).text();
                if ($.isNumeric(debit)) {
                    total = decimalAdd(total, debit);
                }
            });
            $(this).find('div.xml-credit').each(function() {
                credit = $(this).text();
                if ($.isNumeric(credit)) {
                    total = decimalSubtract(total, credit);
                }
            });
            $(this).find('div.xml-total').text(decimalPad(total,2));
        });
    }
    else if (this.object === 'purchaseinvoice') {
        if (this.data["FORMDATA"]) {
            var journal = this.data["FORMDATA"].find('journal').text();
            if ($.isNumeric(journal)) {
                /* PI has been posted to journal - make readonly */
                t.find('input').prop('readonly', true);
                t.find('select').prop('disabled', true);
                t.find('button').hide();
            }
        }
    }
}

Form.prototype.relationshipUpdate =
function (organisation, contact, relationships, refresh) {
    console.log('Updating relationship');
    var form = this;

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
        for (var x = 0; x < relationships.length; x++) {
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
        beforeSend: function(xhr) {
            setAuthHeader(xhr);
        },
        complete: function(xml) {
            console.log('relationship updated');
            if (refresh) {
                form._populateHTMLPanes();
            }
        }
    });
}

Form.prototype.submitErrorCustom = function(xhr, s, err) {
    var xml = xhr.responseXML;
    var responsecode = $(xml).find('responsecode').text();
    var responsetext = $(xml).find('responsetext').text();
    if (this.object === 'account' && this.action === 'create') {
        if (responsecode === '23505') {
            var nomcode = this.tab.find('input.nominalcode').val();
            statusMessage('Unable to save account - nominal code ' + nomcode +
                ' already exists', STATUS_WARN);
            return true;
        }
    }
    else if (this.object === 'product') {
        if (responsecode === 'P0001') {
            statusMessage(responsetext, STATUS_WARN);
            return true;
        }
    }
    else if (this.object === 'salesorder' && this.action === 'process') {
        statusMessage('Billing run failed', STATUS_CRIT);
        return true;
    }
    return false;
}

Form.prototype.submitSuccessCustom = function(xml) {
    if (this.object === 'contact' && this.action === 'update') {
        this.submitSuccessCustomContact(xml);
    }
    else if ((['purchaseorder', 'salesorder'].indexOf(this.object) !== -1)
    && (this.action === 'update'))
    {
        this.processReturnedData = false;
    }
    else if (this.object === 'salesorder' && this.action === 'process') {
        TABS.refresh('salesinvoices');
    }
    return false;
}

Form.prototype.submitSuccessCustomContact = function(xml) {
    var tab;
    var f;
    for (var i = 0; i < TABS.byId.length; ++i) {
        if (TABS.byId[i] !== undefined) {
            console.log(TABS.byId[i].title);
            tab = TABS.byId[i];
            f = tab.form;
            if (f !== undefined) {
                if (f.object === 'organisation' && f.action === "update") {
                    f._populateHTMLPanes();
                }
            }
        }
    }
}

Form.prototype.tabToolClick = function(btn) {
    console.log(btn.attr('title') + ' toolbar button clicked');
    var f = this;
    var t = this.tab.tablet;
    var w = t.find('div.tabworkspace');
    w.empty();
    if (btn.hasClass('btnhome')) {
        btn.removeClass('selected');
        var url = '/html/forms/organisation/detail.html';
        showHTML(url, '', w)
        .done(function() {
                f.map = new Map();
                f.populate(w);
                f.finalize();
                f.updateMap();
        });
    }
    else if (btn.hasClass('btndetails')) {
        /* TODO */
    }
    else if (btn.hasClass('btncontacts')) {
        btn.removeClass('selected');
        var url = '/html/forms/organisation_contact/update.html';
        showHTML(url, '', w)
        .done(function() {
                f._populateHTMLPanes();
        });
    }
    else if (btn.hasClass('btnfinancial')) {
        btn.removeClass('selected');
        var url = '/html/forms/organisation_statement/update.html';
        showHTML(url, '', w)
        .done(function() {
                f._populateHTMLPanes();
        });
    }
    else if (btn.hasClass('btnmap')) {
        w.append('<div class="map-canvas"/>');
        f.updateMap();
    }
    else {
        console.log('unknown tool button - ignoring');
    }
}

Form.prototype.validateCustom = function() {
    console.log('Form().validateCustom()');
    var b = true;

    if (this.object == 'account') {
        return validateFormAccount(this.action, this.id);
    }
    else if (this.object == 'product') {
        return validateFormProduct(this.action, this.id);
    }
    else if (this.object == 'purchaseinvoice') {
        return this.validatePurchaseInvoice();
    }
    else if ((this.object == 'purchaseorder') && (this.action != 'process')) {
        return this.validatePurchaseOrder();
    }
    else if ((this.object == 'salesorder') && (this.action != 'process')) {
        return this.validateSalesOrder();
    }
    else if (this.object == 'salespayment') {
        return validateFormSalesPayment(this.action, this.id);
    }

    return b;
}

Form.prototype.validatePurchaseInvoice = function() {
    console.log('Form().validatePurchaseInvoice()');
    var t = this.tab.tablet;
    var taxpoint = t.find('[name="taxpoint"]');
    var due = t.find('[name="taxpoint"]');
    var subtotal = t.find('[name="subtotal"]');
    var tax = t.find('[name="tax"]');
    var total = t.find('[name="total"]');
    return true;
}

Form.prototype.validatePurchaseOrder = function() {
    console.log('Form().validatePurchaseOrder()');
    var b = true;
    var t = this.tab.tablet;

    var cycle = t.find('[name="cycle"]');
    var start_date = t.find('[name="start_date"]');
    var end_date = t.find('[name="end_date"]');

    if (cycle.val() > 1 && start_date.val() === '') {
        statusMessage('Start Date required for recurring purchase orders',
            STATUS_WARN);
        start_date.focus();
        return false;
    }

    if (start_date.val() !== '' && end_date.val() !== '') {
        if (start_date.val() > end_date.val()) {
            statusMessage('Start Date cannot be after End Date', STATUS_WARN);
            start_date.focus();
            return false;
        }
    }

    return b;
}

Form.prototype.validateSalesOrder = function() {
    console.log('Form().validateSalesOrder()');
    var b = true;
    var t = this.tab.tablet;

    var cycle = t.find('[name="cycle"]');
    var start_date = t.find('[name="start_date"]');
    var end_date = t.find('[name="end_date"]');

    if (cycle.val() > 1 && start_date.val() === '') {
        statusMessage('Start Date required for recurring sales orders',
            STATUS_WARN);
        start_date.focus();
        return false;
    }

    if (start_date.val() !== '' && end_date.val() !== '') {
        if (start_date.val() > end_date.val()) {
            statusMessage('Start Date cannot be after End Date', STATUS_WARN);
            start_date.focus();
            return false;
        }
    }

    return b;
}

Tab.prototype.eventsCustomDrop = function(title, object, id) {
    var form = this.form;
    if (form === undefined) return false;

    if (object === 'contact' && form.object === 'organisation' &&
            form.action === 'update' && id !== undefined)
    {
        /* link contact to organisation */
        console.log('linking contact ' + id + ' to organisation "' +
                form.title + '"');
        form.relationshipUpdate(form.id, id, '', true);
        form.activate();
    }
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
 * displayResultsGeneric()
 * switchBusiness() - refers to orgcode
 */

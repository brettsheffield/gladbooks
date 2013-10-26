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
	[ 'bank.upload', getForm, 'bank', 'upload', 'Upload Bank Statement' ],
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
	[ 'rpt_balancesheet', showHTML, collection_url('reports/balancesheet'),'Balance Sheet',false ],
	[ 'rpt_profitandloss', showHTML, collection_url('reports/profitandloss'),'Profit & Loss',false ],
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
    [ 'account', [ 'accounttypes' ], ],  
    [ 'product', [ 'accounts.revenue' ], ],
    [ 'salesorder', [ 'organisations', 'cycles', 'products' ], ],
    [ 'salespayment', [ 'paymenttype', 'organisations', 'accounts.asset' ], ],
];

var g_max_ledgers_per_journal=7;
var g_frmLedger;
var g_xml_accounttype = '';
var g_xml_business = ''
var g_xml_relationships = '';

function postBankData(xml) {
    showSpinner();
    $.ajax({
        url: collection_url('banks'),
        data: xml,
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

/* TODO  - functions that have Gladbooks-specific stuff in them: */
/* handleSubforms()
 * displayForm()
 * formEvents() - not really, but consider refactoring
 * uploadFile() - has hardcoded /fileupload/ destination
 * formBlurEvents()
 * displaySearchResults()
 * changeRadio()
 * recalculateLineTotal()
 * validateForm()
 * validateFormAccount()
 * validateFormProduct()
 * validateFormSalesOrder()
 * updateSalesOrderTotals()
 * productBoxClone()
 * cloneInput()
 * salesorderAddProduct()
 * resetSalesOrderProductDefaults()
 * populateCombos()
 * loadCombo()
 * populateCombo()
 * validateNominalCode()
 * comboChange()
 * relationshipUpdate()
 * taxProduct()
 * relationshipCombo()
 * prepareSalesOrderData()
 * addSalesOrderProductField()
 * addSalesOrderProducts()
 * addSubFormRows()
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
 * populateAccountsDDowns()
 * populateDepartmentsDDowns()
 * populateDivisionsDDowns()
 * populateDebitCreditDDowns()
 * setupJournalForm()
 * finishJournalForm()
 * validateJournalEntry()
 * submitJournalEntry()
 * submitJournalEntrySuccess()
 * submitJournalEntryError()
 * switchBusiness() - refers to orgcode
 */

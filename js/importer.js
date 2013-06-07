/* 
 * importer.js - gladbooks data import functions
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

var SRC_GLADBOOKS = 0;
var SRC_GLADSERV = 1;
var SRC_PENGUINFACTORY = 2;

$(document).ready(function() {
	console.log('Gladbooks Data Importer loaded.');
	prepMenu();
});

function clickMenu(event) {
	event.preventDefault();

	if ($(this).attr("href") == '#import_gladserv') {
		console.log('Importing Gladserv Ltd data...');
		importData(SRC_GLADSERV);
	}
	else if ($(this).attr("href") == '#import_penguinfactory') {
		console.log('Importing Penguin Factory Ltd data...');
		importData(SRC_PENGUINFACTORY);
	}
	else if ($(this).attr("href") == '#') {
		console.log('Doing nothing, successfully');
	}
	else {
		addTab("Not Implemented", "<h2>Feature Not Available Yet</h2>", true);
	}
}

function importData(src) {
	console.log('importData()');
	var d = new Array();

	showSpinner(); /* tell user to wait */
	d.push(getXML(collection_url('organisations')));
	$.when.apply(null, d)
	.done(function(xml) {
		console.log('data fetched');
		hideSpinner();
	})
	.fail(function() {
		console.log('failed to fetch data');
		hideSpinner();
	});
}

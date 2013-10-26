#!/bin/bash
# print js function names and line numbers
{ egrep -n '^function' js/gladbooks.js |sort -k2|cut -f1 -d\(|awk '{ print $2 " "  "gladbooks.js " $1 }'|cut -f1 -d\: ; 
egrep -n '^function' js/gladd.js |sort -k2|cut -f1 -d\(|awk '{ print $2 " "  "gladd.js " $1 }'|cut -f1 -d\: ; } | sort | less

#!/bin/bash
egrep -n '^function' js/gladbooks.js |sort -k2|cut -f1 -d\(|awk '{ print $2 " "  $1 }'|cut -f1 -d\:|less

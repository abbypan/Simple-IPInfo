#!/bin/bash
perl tidy_ip_loc.pl ip_loc_taobao.csv ip_loc_taobao.tidy.csv
perl compare_ip_loc.pl ip_loc_old.tidy.csv ip_loc_taobao.tidy.csv  ip_loc_compare.csv
perl fix_ip_loc.pl ip_loc_compare.csv ip_loc_fix.csv
perl compare_ip_loc.pl ip_loc_compare.csv ip_loc_fix.csv ip_loc.csv
perl parse_ip_loc.pl ip_loc.csv ip_loc_inet.csv
mv ip_loc_inet.csv IPInfo_LOC.csv
mv ip_loc.csv ip_loc_old.tidy.csv

perl parse_ip_as.pl
mv originas.csv IPInfo_AS.csv

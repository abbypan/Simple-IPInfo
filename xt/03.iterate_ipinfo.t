#!/usr/bin/perl
use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;

my $r = iterate_ipinfo(
    #$inet_arr, 
   '02.inet.test.csv', 
    #id=>0,
    write_file => '02.inet_loc.csv', 
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 0,
    ipinfo_names    => [qw/country prov isp country_code prov_code isp_code/],
    write_head => [qw/inet some country prov isp country_code prov_code isp_code/ ], 
    #skip_head => 1, 
);
print Dumper($r);

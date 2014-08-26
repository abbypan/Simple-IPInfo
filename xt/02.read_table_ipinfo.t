#!/usr/bin/perl
use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;

my $arr = [ [qw/202.38.64.10 xxx/], [qw/8.8.8.8 yyy/], ];

my $r = read_table_ipinfo(
    $arr, 
    0,
    write_file => '02.read_table_ipinfo.csv', 
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 1,
    ipinfo_names    => [qw/state prov isp/],
);

print Dumper($r);

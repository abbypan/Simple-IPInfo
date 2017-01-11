#!/usr/bin/perl
use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;

my $arr = [ [qw/202.38.64.10 xxx/], [qw/8.8.8.8 yyy/], ];

my $r = read_table_ipinfo(
    $arr, 
    0,
    write_file => '02.read_table_ipinfo_loc.csv', 
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 1,
    ipinfo_names    => [qw/state prov isp/],
    write_head => [qw/ip some state prov isp/ ], 
);


print Dumper($r);

my $asn_r = read_table_ipinfo(
    $arr, 
    0,
    write_file => '02.read_table_ipinfo_as.csv', 
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 1,
    ipinfo_file => $Simple::IPInfo::IPINFO_AS_F,
    ipinfo_names    => [qw/as/],
);
print Dumper($asn_r);

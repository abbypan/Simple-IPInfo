#!/usr/bin/perl
#use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;
use utf8;

$Simple::IPInfo::DEBUG=1;

my $r = get_ip_info('202.38.64.10');
print Dumper($r);

my $rr = get_ip_info([ '202.38.64.10', '202.96.196.33' ]);
print Dumper($rr);

my $rr = get_ip_loc([ '202.38.64.10', '202.96.196.33' ]);
print Dumper($rr);

my $rr = get_ip_asn([ '202.38.64.10', '202.96.196.33' ]);
print Dumper($rr);

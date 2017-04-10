#!/usr/bin/perl
use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;
use utf8;

$Simple::IPInfo::DEBUG=1;


my $rr = get_ipinfo([ [ '202.38.64.10'], ['202.96.196.33'] ], reserve_inet=>1);
print Dumper($rr),"\n";

my $rr = get_ip_loc([ [ '202.38.64.10'], ['202.96.196.33'] ]);
print Dumper($rr),"\n";
my $rr = get_ip_loc([ ['3395339297'], ['3391504394'] ]);
print Dumper($rr),"\n";

my $rr = get_ip_as([ ['202.38.64.10'], ['202.96.196.33'] ]);
print Dumper($rr),"\n";

#my $rr = get_ip_loc([ '202.38.64.10', '202.96.196.33' ], use_ip_c =>1 );
#my $r =  get_ipc_info('202.38.64.10', $rr);
#print Dumper($rr, $r);

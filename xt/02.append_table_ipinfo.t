#!/usr/bin/perl
use lib '../lib';
use Simple::IPInfo;
use Data::Dumper;

#my $arr = [ [qw/202.38.64.10 xxx/], [qw/8.8.8.8 yyy/], ];

#my $r = append_table_ipinfo(
    #$arr, 
    #0,
    #write_file => '02.ip_loc.csv', 
    #sep => ',', 
    #charset         => 'utf8',
    #return_arrayref => 1,
    #ipinfo_names    => [qw/country prov isp country_code prov_code isp_code/],
    #write_head => [qw/ip some country prov isp country_code prov_code isp_code/ ], 
#);

#print Dumper($r);

#my $asn_r = append_table_ipinfo(
    #$arr, 
    #0,
    #write_file => '02.ip_as.csv', 
    #sep => ',', 
    #charset         => 'utf8',
    #return_arrayref => 1,
    #ipinfo_file => $Simple::IPInfo::IPINFO_AS_F,
    #ipinfo_names    => [qw/as/],
#);
#print Dumper($asn_r);

#my $inet_arr = [[ '3395339297', 'test'], ['3391504394' , 'ceshi'], ];
my $r = append_table_ipinfo(
    #$inet_arr, 
   '02.inet.test.csv', 
    0,
    write_file => '02.inet_loc.csv', 
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 1,
    ipinfo_names    => [qw/country prov isp country_code prov_code isp_code/],
    write_head => [qw/inet some country prov isp country_code prov_code isp_code/ ], 
    skip_head => 1, 
);
print Dumper($r);

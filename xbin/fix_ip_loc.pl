#!/usr/bin/perl
use SimpleR::Reshape;
use Simple::IPInfo;
use SimpleR::Stat;
use Data::Dumper;
use utf8;

our $MIN_CNT = 1;
our $MIN_RATE = 0.8;

$Simple::IPInfo::DEBUG = 1;

my ($src, $dst) = @ARGV; 
read_table_ipinfo(
    $src, 
    0,
    write_file => "$dst.asn", 
    skip_sub => sub { $_[0][1] ne '中国' ? 1 : 0 } ,
    sep => ',', 
    charset         => 'utf8',
    return_arrayref => 0,
    ipinfo_file => $Simple::IPInfo::IPINFO_AS_F,
    ipinfo_names    => [qw/as/],
);

cast(
    "$dst.asn", 
    cast_file => "$dst.asn.isp.cnt", 
    sep => ',', 
    names => [ qw/ip state prov isp asn/ ], 
    id => [ 4 ],
    skip_sub => sub { (! $_[0][4] or $_[0][4] eq '未知') ? 1 : 0 } ,
    measure => [3], 
    value => sub { 1 }, 
    reduce_sub => sub { my ($last, $now) = @_; return $last+$now; }, 
    charset         => 'utf8',
    write_head => 1, 
    default_cell_value => 0,
    return_arrayref => 0, 
);

open my $fh, '<:utf8', "$dst.asn.isp.cnt";
my $head = <$fh>;
close $fh;
chomp $head;
my @header = split /,/, $head;
shift @header;

my %asn_isp;
read_table("$dst.asn.isp.cnt", 
    write_file=> "$dst.asn.isp.csv", 
    sep=>',', 
    charset         => 'utf8',
    skip_head => 1, 
    conv_sub => sub {
        my ($r) = @_;
        my ($asn, @isp_cnt) = @$r;
        my $sum = sum_arrayref(\@isp_cnt);
        return if($sum<$MIN_CNT);

        my $rate = calc_rate_arrayref(\@isp_cnt);
        my @x = grep { $rate->[$_]>=$MIN_RATE} ( 0 .. $#$rate);
        return unless(@x);

        my $isp = $header[$x[0]];
        $asn_isp{$asn} = $isp;
        return [ $asn, $isp ]; 
    }, 
);

read_table("$dst.asn", 
    write_file=> "$dst", 
    sep=>',', 
    charset         => 'utf8',
    skip_head => 1, 
    conv_sub => sub {
        my ($r) = @_;
    names => [ qw/ip state prov isp asn/ ], 
        my ($ip, $state, $prov, $isp, $asn) = @$r;

        if($asn and $asn=~/^\d+$/){
            $isp = $asn_isp{$asn};
        return [ $ip, $state, $prov, $isp ] if($isp and $isp ne '未知'); 
        }
        return;
    }, 
);
#unlink("$dst.asn");
#unlink("$dst.asn.isp.cnt");

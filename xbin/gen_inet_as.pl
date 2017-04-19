#!/usr/bin/perl
#ip as info is from: ftp://routeviews.org/dnszones/originas.bz2
use Net::CIDR qw/cidr2range/;
use Socket qw/inet_aton/;
use SimpleR::Reshape;

my ($dst) = @ARGV;
$dst ||= 'inet_as.csv';

system("curl ftp://routeviews.org/dnszones/originas.bz2 -o originas.bz2");
system("bunzip2 -f originas.bz2");

my $temp = "originas.inet";
parse_raw_file("originas", $temp);
system(qq[sort -t, -k1 -n $temp | uniq > $temp.sort]);
system(qq[refine_inet.pl $temp.sort $dst]);

unlink($temp);
unlink("$temp.sort");

sub parse_raw_file {
    my ( $raw, $temp ) = @_;
    open my $fh,  '<', $raw;
    open my $fhw, '>', $temp;
    print $fhw "-1,-1,-1\n";
    while (<$fh>) {
        my $rr = extract_asn_line($_);
        print $fhw join(",", @$rr),"\n";
    }
    close $fhw;
    close $fh;
    return $temp;
}

sub extract_asn_line {
    my ($line) = @_;
    chomp $line;

    my @data = split /\s+/, $line, -1;
    s/"//g for @data;
    my @r = cidr2range("$data[-2]/$data[-1]");
    my ( $s_ip, $e_ip ) = $r[0] =~ /(.+?)-(.+)/;
    my ( $s_inet, $e_inet ) = map { unpack( 'N', inet_aton($_) ) } ( $s_ip, $e_ip );

    $data[-3]=~s/[\{\} ]//sg;
    $data[-3]=~s/,.*//; # { n, m } only extract n
    return [ $s_inet, $e_inet, $data[-3] ] ;
}

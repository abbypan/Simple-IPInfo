#!/usr/bin/perl
#ip as info is from: ftp://routeviews.org/dnszones/originas.bz2
use Net::CIDR qw/cidr2range/;
use Socket qw/inet_aton/;
use SimpleR::Reshape;

system("curl ftp://routeviews.org/dnszones/originas.bz2 -o originas.bz2");
system("bunzip2 originas.bz2");
parse_raw_file("originas", "originas.temp");
parse_raw_file('originas.temp', 'originas.csv');

sub parse_raw_file {
    my ( $raw, $temp ) = @_;
    my ( $s, $e, $n ) = ( -1, -1, -1 );
    open my $fh,  '<', $raw;
    open my $fhw, '>', $temp;
    while (<$fh>) {
        my ( $s_inet, $e_inet, $asn ) = extract_asn_line($_);
        next unless($s_inet=~/^\d+$/ and $e_inet=~/^\d+$/ and $asn=~/^\d+$/);
        next if ( $e_inet == $e );
        if ( $n == $asn and $s_inet == ( $e + 1 ) ) {
            $e = $e_inet;
        }
        else {
            print $fhw "$s,$e,$n\n";
            ( $s, $e, $n ) = ( $s_inet, $e_inet, $asn );
        }
    }
    print $fhw "$s,$e,$n\n";
    close $fhw;
    close $fh;

    my $d = read_table( $temp, sep => ',', return_arrayref => 1 );
    $d = [ sort { $a->[0] <=> $b->[0] } @$d ];
    unshift @$d, [ qw/s e as/ ];
    write_table( $d, file => $temp, sep => ',' );
    return $temp;
}

sub extract_asn_line {
    my ($line) = @_;
    chomp $line;
    return ( split /,/, $line ) if ( $line =~ /,/ );

    my @data = split /\s+/, $line;
    s/"//g for @data;
    my @r = cidr2range("$data[-2]/$data[-1]");
    my ( $s_ip, $e_ip ) = $r[0] =~ /(.+?)-(.+)/;
    my ( $s_inet, $e_inet ) =
      map { unpack( 'N', inet_aton($_) ) } ( $s_ip, $e_ip );
    return ( $s_inet, $e_inet, $data[-3] );
}

#!/usr/bin/perl
#ip as info is from: ftp://routeviews.org/dnszones/originas.bz2
use SimpleR::Reshape;
use JSON;

#rember edit originas.csv, delete error line
write_asn_json( 'originas.csv', 'IPInfo_AS.json' );

sub write_asn_json {
    my ( $src, $dst ) = @_;

    my $d = read_table( $src, sep => ',' );
    my @data =
      map { { s => $_->[0], e => $_->[1], as => $_->[2] } } @$d;
    my $s = to_json( \@data );
    $s =~ s/},{/},\n{/sg;
    open my $fh, '>', $dst;
    print $fh $s;
    close $fh;
}

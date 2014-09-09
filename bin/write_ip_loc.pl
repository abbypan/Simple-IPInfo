#!/usr/bin/perl
use SimpleR::Reshape;
use JSON;
use utf8;
$| = 1;

my ( $src, $dst ) = @ARGV;

#manual edit $src, delete error line
write_loc_json( $src, $dst);

sub write_loc_json {
    my ( $src, $dst ) = @_;

    my $d = read_table( $src, sep => ',' );
    my @data =
      map {
        my %temp;
        @temp{qw/s e state prov isp/} = @$_;
        \%temp;
      } @$d;

    my $s = to_json( \@data );
    $s =~ s/},{/},\n{/sg;

    open my $fh, '>', $dst;
    print $fh $s;
    close $fh;
}

#!/usr/bin/perl
use strict;
use warnings;

use Net::CIDR qw/cidr2range/;
use Socket qw/inet_aton/;

my ( $src, $dst ) = @ARGV;
exit unless ( -f $src );

$dst //= "$src.inet";

open my $fh,  '<', $src;
open my $fhw, '>', $dst;

chomp( my $h = <$fh> );
my @head = split ',', $h;
shift @head;

print $fhw join( ",", 's', 'e', @head ), "\n";
while ( <$fh> ) {
  chomp;
  my @d = m#("[^"]*",|[^,]*,|[^,]*$)#g;
  s/,$//  for @d;
  s/"//g  for @d;
  s/,/ /g for @d;

  my @inf = cidr2range( "$d[0]" );
  my ( $s_ip, $e_ip ) = $inf[0] =~ /(.+?)-(.+)/;
  my ( $s_inet, $e_inet ) = map { unpack( 'N', inet_aton( $_ ) ) } ( $s_ip, $e_ip );
  shift @d;
  print $fhw join( ",", $s_inet, $e_inet, @d ), "\n";
}
close $fhw;
close $fh;

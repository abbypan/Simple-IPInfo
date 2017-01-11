#!/usr/bin/perl
use Socket;

my ($f) = @ARGV;
open my $fh, '<', $f;
open my $fhw, '>', "$f.test";
while(<$fh>){
my ($ip) = /^(.+?),/;
my $n = unpack( "N",inet_aton($ip));
print $fhw "$n,$_";
}
close $fhw;
close $fh;



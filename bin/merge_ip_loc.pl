#!/usr/bin/perl

my ($dst_f) = @ARGV;
$dst_f ||= 'ip_loc_c.txt';
open my $fhw, '>', $dst_f;
for my $i ( 0 .. 255 ){
    print "$i\n";
    for my $j ( 0 .. 255 ){
        open my $fh, '<', "data/$i/ip.$i.$j.csv";
        while(<$fh>){
            print $fhw $_;
        }
        close $fh;
    }
}
close $fhw;

#!/usr/bin/perl

my ($old, $new) =@_;

open my $fh, '>', $new;
for my $i ( 0 .. 255 ){
    print "$i\n";
    my @data;
    open my $fhr,'<', $old;
    while(<$fhr>){
        my ($x, $y, $z) = /(.+?)\.(.+?)\.(.+?)\./;
        next unless($i==$x);
        $data[$y][$z] = $_;
    }
    close $fhr;

    next unless(@data);
    for my $d (@data){
        print $fh $_ for @$d;
    }
}
close $fh;

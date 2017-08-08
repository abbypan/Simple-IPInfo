#!/usr/bin/perl
use strict;
use warnings;

my ( $f, $dst_f ) = @ARGV;
$dst_f ||= "$f.refine";

my $split_inet_f = cut_old_e_with_s($f, "$dst_f.cut_old_e");

system(qq[sort -t, -n -k 2,2 -k 1,1 "$split_inet_f" > "$dst_f.sort"]);

cut_s_with_old_e("$dst_f.sort", "$dst_f.cut_s");
merge_d("$dst_f.cut_s", $dst_f);

unlink("$dst_f.cut_old_e");
unlink("$dst_f.sort");
unlink("$dst_f.cut_s");

sub merge_d {
    my ($src, $dst) = @_;

    open my $fh, '<', $src;
    my $head = <$fh>;
    my ( $old_s, $old_e, $old_d ) = $head =~ m#^(.+?),(.+?),(.*)$#;

    open my $fhw, '>', $dst;
    while ( <$fh> ) {
        chomp;
        my ( $s, $e, $d ) = m#^(\d+),(\d+),(.*)$#;
        $d //= '';

        if(($d eq $old_d) and ($s==$old_e+1)){
            ( $old_s, $old_e, $old_d ) = ( $old_s, $e, $d );
        }else{
            print $fhw join(",", $old_s, $old_e, $old_d),"\n";
            ( $old_s, $old_e, $old_d ) = ( $s, $e, $d );
        }
    }
    print $fhw join( ",", $old_s, $old_e, $old_d ), "\n";
    close $fhw;
    close $fh;

    return $dst;
}

sub cut_s_with_old_e {
    my ($src, $dst) = @_;

    open my $fh, '<', $src;
    my $head = <$fh>;
    my ( $old_s, $old_e, $old_d ) = $head =~ m#^(.+?),(.+?),(.*)$#;

    open my $fhw, '>', $dst;
    while ( <$fh> ) {
        chomp;
        my ( $s, $e, $d ) = m#^(\d+),(\d+),(.*)$#;
        $d //= '';

        print $fhw join(",", $old_s, $old_e, $old_d),"\n";

        if($old_e>=$s){
            $s = $old_e + 1;
        }

        ( $old_s, $old_e, $old_d ) = ( $s, $e, $d );
    }
    print $fhw join( ",", $old_s, $old_e, $old_d ), "\n";
    close $fhw;
    close $fh;

    return $dst;
}

sub cut_old_e_with_s {
    my ($src, $dst) = @_;

    open my $fh, '<', $src;
    my $head = <$fh>;
    my ( $old_s, $old_e, $old_d ) = $head =~ m#^(.+?),(.+?),(.*)$#;

    open my $fhw, '>', $dst;
    while ( <$fh> ) {
        chomp;
        my ( $s, $e, $d ) = m#^(\d+),(\d+),(.*)$#;
        $d //= '';

        if($old_e>=$s){
            if($s-1>=$old_s){
                print $fhw join(",", $old_s, $s-1, $old_d),"\n";
            }
            print $fhw join(",", $s, $old_e, $old_d),"\n";
        }else{
            print $fhw join(",", $old_s, $old_e, $old_d),"\n";
        }

        ( $old_s, $old_e, $old_d ) = ( $s, $e, $d );
    }
    print $fhw join( ",", $old_s, $old_e, $old_d ), "\n";
    close $fhw;
    close $fh;

    return $dst;
}

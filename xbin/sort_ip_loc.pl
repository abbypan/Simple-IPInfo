#!/usr/bin/perl
use Socket;
use utf8;
$|=1;

my ($old, $new) = @ARGV;

open my $fhn, '>:utf8', $new;

for my $i (1 .. 255){
    open my $fho, '<:utf8', $old;
    my %mem=();
    while(my $oc=<$fho>){
        next unless($oc=~/^$i\./);
        my ($old_n , @old_data) = read_one_line($oc);
        if(exists $mem{$old_n}){
            $mem{$old_n} = [ select_data($mem{$old_n}, \@old_data) ];
        }else{
            $mem{$old_n} = \@old_data;
        }
    }
    close $oc;
    print $fhn join(",", @{$mem{$_}}), "\n" for sort keys(%mem);
}
close $fhw;

sub select_data {
    my ($old, $new) = @_;
    my ($ip_o, $o_s, $o_p, $o_i) = @$old;
    my ($ip_n, $n_s, $n_p, $n_i) = @$new;
    #print "old ($ip_o, $o_s, $o_p, $o_i), new ($ip_n, $n_s, $n_p, $n_i)\n";

    my ($s, $p, $i);
    if($n_s eq '未知'){
        ($s, $p, $i)=($o_s, $o_p, $o_i);
    }elsif($n_s eq $o_s and $n_i eq '未知'){
        $s = $n_s; $i = $o_i;
        $p = $n_p eq '未知' ? $o_p : $n_p;
    }elsif($n_s eq $o_s and $n_p eq '未知'){
        $s = $n_s; $i = $n_i;
        $p = $o_p;
    }else{
        ($s, $p, $i)=($n_s, $n_p, $n_i);
    }

    return ($ip_n, $s, $p, $i);
}

sub read_one_line {
    my ($line) = @_;
    chomp($line);
    $line=~s///;
    $line=~s/\.1,/.0,/;
    return unless($line);

    my @data = split /,/, $line;
    my $n = unpack('N', inet_aton($data[0]));
    return ($n, @data);
}

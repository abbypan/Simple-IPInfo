#!/usr/bin/perl
use Socket;
use utf8;
$|=1;

my ($old, $new, $dst) = @ARGV;

open my $fho, '<:utf8', $old;
open my $fhn, '<:utf8', $new;
open my $fhw, '>:utf8', $dst;

my $oc = <$fho>;
my ($old_n , @old_data) = read_one_line($oc);
my $nc = <$fhn>;
my ($new_n , @new_data) = read_one_line($nc);
my $i=0;
my $o_f = 0;
my $n_f = 0;
while(1){
    last if($o_f and $n_f);

    $i++;
    print "\r$i" if($i % 1000==0);

    if(! $old_n or $new_n<$old_n){
        print $fhw join(",", @new_data),"\n";
        my $nc = <$fhn>;
        $n_f = 1 unless($nc);
        ($new_n , @new_data) = read_one_line($nc);
    }elsif(! $new_n or $new_n>$old_n){
        print $fhw join(",", @old_data),"\n";
        my $oc = <$fho>;
        $o_f = 1 unless($oc);
        ($old_n , @old_data) = read_one_line($oc);
    }elsif($new_n and $old_n and $new_n==$old_n){
        my @sd = select_data(\@old_data, \@new_data);
        print $fhw join(",", @sd),"\n";

        my $oc = <$fho>;
        $o_f = 1 unless($oc);
        ($old_n , @old_data) = read_one_line($oc);
        my $nc = <$fhn>;
        $n_f = 1 unless($nc);
        ($new_n , @new_data) = read_one_line($nc);
    }
}
close $fhw;
close $oc;
close $nc;

sub select_data {
    my ($old, $new) = @_;
    my ($ip_o, $o_s, $o_p, $o_i) = @$old;
    my ($ip_n, $n_s, $n_p, $n_i) = @$new;

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
    return unless($line);

    my @data = split /,/, $line;
    my $n = unpack('N', inet_aton($data[0]));
    return ($n, @data);
}

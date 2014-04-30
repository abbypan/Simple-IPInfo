#!/usr/bin/perl
use Socket;

my ($old, $new, $dst) = @ARGV;

open my $fho, '<', $old;
my $read_fho = sub { <$fho> };
open my $fhn, '<', $new;
my $read_fhn = sub { <$fhn> };
open my $fhw, '>', $dst;

my ($old_n , @old_data) = read_one_line($read_fho);
my ($new_n , @new_data) = read_one_line($read_fhn);
while(1){
    last unless($new_n or $old_n);

    if(! $old_n or $new_n<$old_n){
        print $fhw join(",", @new_data),"\n";
        ($new_n , @new_data) = read_one_line($read_fhn);
    }elsif(! $new_n or $new_n>$old_n){
        print $fhw join(",", @old_data),"\n";
        ($old_n , @old_data) = read_one_line($read_fho);
    }elsif($new_n and $old_n and $new_n==$old_n){
        my @sd = select_data(\@old_data, \@new_data);
        print $fhw join(",", @sd),"\n";
        ($old_n , @old_data) = read_one_line($read_fho);
        ($new_n , @new_data) = read_one_line($read_fhn);
    }
}

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
    my ($read) = @_;

    my $line = $read->();
    return unless($line);
    chomp($line);

    my @data = split /,/, $line;
    $data[0]=~s/\.1$/.0/;
    $data[$_] ||='未知'  for ( 0 .. 3);
    $data[3]=~s/教育网/教育/g;

    my $n = unpack('N', inet_aton($ip));
    return ($n, @data);
}

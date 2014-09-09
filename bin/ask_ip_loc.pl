#!/usr/bin/perl
use JSON;
use Encode;
use Data::Validate::IP;
use FindBin;
$|=1;

our $DATA_DIR='data';
exit if(-f "$DATA_DIR/*.temp");


my ($i) = @ARGV;
$i = select_file_id() if(!$i);

write_ip_c($i);

sub write_ip_c {
	my ($i) = @_;
	print "$i\n";

	my $file = "$DATA_DIR/$i.csv";
	open my $fh,'>', "$file.temp";
	close $fh;

	open my $fh,'>', "$file.temp";
	for my $j ( 0 .. 255 ){
		for my $k (0 .. 255){
			my $ip = "$i.$j.$k.1";
			print "\r$ip";
			next unless ( is_public_ipv4($ip) );
			my $r = ask_ip_taobao($ip);
			my $info =join(",",@{$r}{qw/ip country region isp/});
			print $fh $info, "\n";
		}
	}
	close $fh;

	rename("$file.temp", $file);
	return $file;
}

sub ask_ip_taobao {
	my ($ip) = @_;

	my $url = "http://ip.taobao.com/service/getIpInfo.php?ip=$ip";
    my $c = `curl -s "$url"`;
	my $r = decode_json($c);
	my $h = $r->{data};
	$h->{$_} = encode( 'utf8' =>  $h->{$_}, Encode::FB_CROAK)
		for keys(%$h);
	return $h;
}

sub select_file_id {
	my @files = map { $_->[0] } 
	sort { $a->[1] <=> $b->[1] } 
	map { [ $_, (stat($_))[9] ] } 
	glob("$DATA_DIR/*.csv");
	my $f = $files[0];
	my ($i) = $f=~m#$DATA_DIR/(\d+).csv#;
	return $i;
}

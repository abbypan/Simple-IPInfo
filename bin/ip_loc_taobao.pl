#!/usr/bin/perl
#ip loc info from：http://ip.taobao.com
use LWP::UserAgent;
use JSON;
use Encode;
use Data::Validate::IP;
use FindBin;
$|=1;

chdir("$FindBin::RealBin");

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;

my ($f) = @ARGV;

if(!$f){
	init_data();
	$f = select_file();
}

my ($i, $j) = $f=~/ip\.(\d+)\.(\d+)/;
write_ip_c($i,$j, "$f.temp");
rename("$f.temp", $f);

sub select_file {
	my @files = map { $_->[0] } sort { $a->[1] <=> $b->[1] } map { [ $_, (stat($_))[9] ] } glob("data/*/*.csv");
	my $i=0;
	while(1){
		last unless(-f "$files[$i].temp");
		$i++;
	}
	my $f = $files[$i];
	print "select $f\n";
	return $f;
}

sub init_data {
	return if(-d "data");
	mkdir("data");
	for my $i ( 0 .. 255 ){
		mkdir("data/$i");
		for my $j ( 0 .. 255){
			my $f="data/$i/ip.$i.$j.csv";
			open my $fh, '>', $f;
			close $fh;
		}
	}
}

sub write_ip_c {
	my ($i, $j, $file) = @_;
	open my $fh,'>', $file;
	close $fh;
	open my $fh,'>', $file;
	for my $k (0 .. 255){
		my $ip = "$i.$j.$k.1";
		print "\r$ip";
		next unless ( is_public_ipv4($ip) );
		my $r = ask_ip_taobao($ua, $ip);
		my $info =join(",",@{$r}{qw/ip country region isp/});
		print $fh $info, "\n";
	}
	close $fh;
	return $file;
}

sub ask_ip_taobao {
	my ($ua, $ip) = @_;

	my $url = "http://ip.taobao.com/service/getIpInfo.php?ip=$ip";
	my $response = $ua->get($url);
	return unless($response->is_success);

	my $c = $response->decoded_content;  
	my $r = decode_json($c);
	my $h = $r->{data};
	$h->{$_} = encode( 'utf8' =>  $h->{$_}, Encode::FB_CROAK)
		for keys(%$h);
	return $h;
}

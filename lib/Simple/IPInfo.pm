# ABSTRACT: Get IP/IPList Info (location, as number, etc)
package Simple::IPInfo;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  get_ip_loc
  get_ip_asn
  get_ip_info
);
use utf8;
use Data::Validate::IP qw/is_ipv4 is_ipv6 is_public_ipv4/;
use File::Spec;
use JSON;
use Memoize;
use Socket qw/inet_aton/;
memoize('read_ipinfo');

our $DEBUG = 0;

our $VERSION=0.01;

my ( $vol, $dir, $file ) = File::Spec->splitpath(__FILE__);
our $IPINFO_LOC_F = File::Spec->catpath( $vol, $dir, "IPInfo_LOC.json" );
our $IPINFO_ASN_F = File::Spec->catpath( $vol, $dir, "IPInfo_ASN.json" );

our $UNKNOWN =
  { state => '未知', prov => '未知', isp => '未知', asn => '未知' };
our $ERROR =
  { state => '无效', prov => '无效', isp => '无效', asn => '无效' };
our $LOCAL = {
    state => '局域网',
    prov  => '局域网',
    isp   => '局域网',
    asn   => '局域网'
};

sub calc_ip_inet {
    my ($ip) = @_;
    my $n = unpack( "N", inet_aton($ip) );
    return $n;
}

sub calc_ip_list_inet {
    my ($ip_list) = @_;
    $ip_list = [$ip_list] if ( ref($ip_list) ne 'ARRAY' );

    my %temp_ip = map { $_ => 1 } @$ip_list;
    my @uniq_ip_list = keys %temp_ip;

    my @ip_inet = sort { $a->[1] <=> $b->[1] } map {
        [
            $_,
            ( not is_ip($_) )          ? $ERROR
            : ( not is_public_ip($_) ) ? $LOCAL
            :                            calc_ip_inet($_)
        ]
    } @uniq_ip_list;
    return \@ip_inet;
}

sub get_ip_asn {
    my ( $ip_list, %opt ) = @_;
    $opt{ip_info_file} = $IPINFO_ASN_F;
    return get_ip_info( $ip_list, %opt );
}

sub get_ip_loc {
    my ( $ip_list, %opt ) = @_;
    $opt{ip_info_file} = $IPINFO_LOC_F;
    return get_ip_info( $ip_list, %opt );
}

sub get_ip_info {

    # large amount ip can use this function
    # ip array ref => ( ip => { state,prov,area,isp } )
    my ( $ip_list, %opt ) = @_;

    my $ip_inet = calc_ip_list_inet($ip_list);

    print "get ip info begin\n" if($DEBUG);

    my $ip_info = read_ipinfo( $opt{ip_info_file} );

    my $n = $#$ip_info;

    my %result;

    my ( $i, $r ) = ( 0, $ip_info->[0] );
    my ( $s, $e ) = @{$r}{qw/inet_s inet_e/};

    for my $x (@$ip_inet) {
        my ( $ip, $inet ) = @$x;
        print "\r$ip, $s, $e, $inet" if($DEBUG);

        if ( ref($inet) eq 'HASH' ) {
            $result{$ip} = $inet;
            next;
        }
        elsif ( $inet < $s or $i > $n ) {
            $result{$ip} = $UNKNOWN;
            next;
        }

        while ( $inet > $e and $i < $n ) {
            $i++;
            $r = $ip_info->[$i];
            ( $s, $e ) = @{$r}{qw/inet_s inet_e/};
        }

        if ( $inet >= $s and $inet <= $e and $i <= $n ) {
            $result{$ip} = $r;
        }
    }

    print "\nget ip info end\n" if($DEBUG);

    return \%result;
} ## end sub get_ip_loc_isp_gslb

sub read_ipinfo {
    my ( $f, $charset ) = @_;
    $f ||= $IPINFO_LOC_F;
    $charset ||= 'utf8';

    local $/;
    open my $fh, "<:$charset", $f;
    my $c = <$fh>;
    close $fh;

    return from_json($c);
}

sub is_ip {
    my ($ip) = @_;
    return 1 if ( is_ipv4($ip) );
    return 1 if ( is_ipv6($ip) );
    return;
} ## end sub check_ip

sub is_public_ip {
    my ($ip) = @_;
    return 1 if ( is_public_ipv4($ip) );
    return;
} ## end sub check_extnet_ip

1;

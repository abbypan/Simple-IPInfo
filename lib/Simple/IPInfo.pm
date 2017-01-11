# ABSTRACT: Get IP/IPList Info (location, as number, etc)
package Simple::IPInfo;
require Exporter;
@ISA    = qw(Exporter);
@EXPORT = qw(
  get_ip_loc
  get_ip_as
  get_ip_info
  read_table_ipinfo
  get_ipc_info
  get_ipinfo_by_curl
  read_ipinfo
);
use utf8;
use Data::Validate::IP qw/is_ipv4 is_ipv6 is_public_ipv4/;
use SimpleR::Reshape;
use JSON;
use File::Spec;
use Memoize;
use Socket qw/inet_aton/;
memoize('read_ipinfo');

our $DEBUG = 0;

our $VERSION=0.07;

my ( $vol, $dir, $file ) = File::Spec->splitpath(__FILE__);
our $IPINFO_LOC_F = File::Spec->catpath( $vol, $dir, "IPInfo_LOC.csv" );
our $IPINFO_AS_F = File::Spec->catpath( $vol, $dir, "IPInfo_AS.csv" );

our $UNKNOWN =
  { state => '未知', prov => '未知', isp => '未知', as => '未知' };
our $ERROR =
  { state => '无效', prov => '无效', isp => '无效', as => '无效' };
our $LOCAL = {
    state => '局域网',
    prov  => '局域网',
    isp   => '局域网',
    as   => '局域网'
};


sub get_ipinfo_by_curl {
    my ($ip) = @_;
    my $s = `curl -s ipinfo.io/$ip/json`;
    my $r = decode_json $s;

    my ($asn, $isp)= $r->{org}=~m#AS(\d+)\s*(.*)#;
    if($r->{country} eq 'CN'){
        $isp = $isp=~/\bTelecom\b/ ? '电信' : 
        $isp=~/\bCNCGROUP\b/ ?  '联通' :
        $isp=~/\bTieTong\b/ ? '铁通':
        $isp=~/\bEducation\b/ ? '教育' :
        $isp=~/\bMobile Communication\b/ ? '移动' : $isp;
    }

    $r = {
        ip => $r->{ip}, 
        loc => $r->{loc}, 
        country => $r->{country}, 
        isp => $isp, 
        as => $asn, 
    };
    return $r;
}

sub read_table_ipinfo {
    my ( $arr, $id, %o ) = @_;
    $o{ipinfo_file} ||= $IPINFO_LOC_F;
    $o{ipinfo_names} ||= [qw/state prov isp/];

    #my %ip = map { $_->[$id] => 1 } @$arr;
    #my $loc = get_ip_loc( [ keys %ip ], %o );
    my %ip_c;
    read_table(
        $arr, %o,
        return_arrayref => 0, 
        write_file=> undef, 
        write_head => undef, 
        conv_sub => sub {
            my ($r) = @_;

            my $ip = $r->[$id];
            $ip=~s/\.\d+$/.0/;
            $ip_c{$ip} = 1;

            #[ @$r, @{ $loc->{ $r->[$id] } }{ @{ $o{ipinfo_names} } } ];
        }
    );

    my $ip_info = get_ip_info([ keys %ip_c ], %o);
    read_table(
        $arr, %o,
        conv_sub => sub {
            my ($r) = @_;

            my $ip = $r->[$id];
            $ip=~s/\.\d+$/.0/;

            $ip_info->{$ip}{$_} ||='未知' for @{ $o{ipinfo_names} };

            [ @$r, @{ $ip_info->{ $ip } }{ @{ $o{ipinfo_names} } } ];
        }
    );
}


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

sub get_ip_as {
    my ( $ip_list, %opt ) = @_;
    $opt{ip_info_file} = $IPINFO_AS_F;
    return get_ip_info( $ip_list, %opt );
}

sub get_ip_loc {
    my ( $ip_list, %opt ) = @_;
    $opt{ip_info_file} = $IPINFO_LOC_F;
    return get_ip_info( $ip_list, %opt );
}

sub get_ipc_info {
    my ($ip, $info) = @_;
    my $ip_c = $ip;
    $ip_c=~s/\.\d+$/.0/;
    return $info->{$ip_c};
}

sub get_ip_info {

    # large amount ip can use this function
    # ip array ref => ( ip => { state,prov,area,isp } )
    my ( $ip_list, %opt ) = @_;
    $opt{step} ||= $#$ip_list;

    if($opt{use_ip_c}){
        s/\.\d+$/.0/ for @$ip_list;
    }

    my $ip_inet = calc_ip_list_inet($ip_list);

    print "get ip info begin\n" if($DEBUG);

    my $ip_info = read_ipinfo( $opt{ipinfo_file} );

    my $n = $#$ip_info;

    my %result;

    my ( $i, $r ) = ( 0, $ip_info->[0] );
    my ( $s, $e ) = @{$r}{qw/s e/};

    for(my $ip_i =0; $ip_i<=$#$ip_list; $ip_i+=$opt{step}+1) {
        my $ip_j = $ip_i + $opt{step} ;
        print "check ip $ip_i -> $ip_j\n" if($DEBUG);

        for my $x (@{$ip_inet}[ $ip_i .. $ip_j ]) {
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
                ( $s, $e ) = @{$r}{qw/s e/};
            }

            if ( $inet >= $s and $inet <= $e and $i <= $n ) {
                $result{$ip} = $r;
            }
        }
    }

    print "\nget ip info end\n" if($DEBUG);

    return \%result;
} ## end sub get_ip_loc_isp_gslb

sub read_ipinfo {
    my ( $f, $charset ) = @_;
    $f ||= $IPINFO_LOC_F;
    $charset ||= 'utf8';

    #local $/;
    my @d;
    open my $fh, "<:$charset", $f;
    chomp(my $h = <$fh>);
    my @head = split /,/, $h;
    while(my $c=<$fh>){
        chomp($c);
        my @line = split /,/, $c;
        my %k = map { $head[$_] => $line[$_] } ( 0 .. $#head );
        push @d, \%k;
    }
    close $fh;
    return \@d;
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

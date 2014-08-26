#!/usr/bin/perl
#ip as info is from: ftp://routeviews.org/dnszones/originas.bz2
use Net::CIDR qw/cidr2range/;
use Socket qw/inet_aton/;
use SimpleR::Reshape;
use JSON;
#use utf8;
use IO::Handle;
$|=1;

parse_raw_file('ip_loc_c.txt', 'ip_loc_inet.csv');

#edit ip_loc_inet.csv, delete error line
#write_loc_json( 'ip_loc_inet.csv', 'IPInfo_LOC.json' );

sub write_loc_json {
    my ( $src, $dst ) = @_;

    my $d = read_table( $src, sep => ',' );
    my @data =
      map { { inet_s => $_->[0], inet_e => $_->[1], 
          state => $_->[2], 
          prov => $_->[3], 
          isp => $_->[4], 
      } } @$d;
    my $s = to_json( \@data );
    $s =~ s/},{/},\n{/sg;
    open my $fh, '>', $dst;
    print $fh $s;
    close $fh;
}

sub parse_raw_file {
    my ( $raw, $temp ) = @_;
    my ( $s, $e, $s_state, $s_prov, $s_isp ) = ( -1, -1, 
        '无效', '无效', '无效', );
    open my $fh,  '<', $raw;
    open my $fhw, '>', $temp;
    $fhw->autoflush(1);

    my $all_lines = 0;
    my $merge_lines=0;
    while (<$fh>) {
        $all_lines++;
        print $all_lines, "\n" if($all_lines % 1000000==0);
        my ( $s_inet, $e_inet, $data_ref) = extract_loc_line($_);


        next if ( ! $s_inet or ! $e_inet);

        $data_ref->[1]=~s/省|市//;
        $data_ref->[1]=~s/(内蒙古|宁夏|新疆|广西|香港).*/$1/;
        $data_ref->[2]=~s/省|市//;

        if (  $s_inet == ( $e + 1 ) and 
            $data_ref->[1] eq $s_state and
            $data_ref->[2] eq $s_prov and 
            $data_ref->[3] eq $s_isp
        ) {
            $e = $e_inet;
            $merge_lines++;
        }
        else {

        #use Encode;
        #print encode("cp936", decode("utf8", "\rall $all_lines, merge $merge_lines :write [ $s, $e, $s_state, $s_prov, $s_isp ] now ( $s_inet, $e_inet, $state, $prov, $isp)"));

            print $fhw "$s,$e,$s_state,$s_prov,$s_isp\n";
            ( $s, $e, $s_state, $s_prov, $s_isp ) = 
                ( $s_inet, $e_inet, @{$data_ref}[1..3]);
                $merge_lines=0;
        }
    }
    print $fhw "$s,$e,$s_state,$s_prov,$s_isp\n";
    close $fhw;
    close $fh;

    my $d = read_table( $temp, sep => ',', return_arrayref => 1, charset => 'utf8' );
    $d = [ sort { $a->[0] <=> $b->[0] } @$d ];
    write_table( $d, file => $temp, sep => ',' , charset=> 'utf8');
    return $temp;
}

sub extract_loc_line {
    #ip_c, state, prov, isp
    my ($line) = @_;
    chomp $line;
    my @data = split /,/, $line;
    #s/"//g for @data;
    my $s_inet = unpack('N', inet_aton($data[0]));
    my $e_inet = $s_inet + 255;
    
    return ( $s_inet, $e_inet, \@data );
}

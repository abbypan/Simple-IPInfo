#!/usr/bin/perl
use Socket qw/inet_aton/;
use SimpleR::Reshape;
use IO::Handle;
$| = 1;

my ( $src, $dst ) = @ARGV;

map_ipc_to_inet( $src, $dst );

sub map_ipc_to_inet {
    my ( $raw, $dst ) = @_;
    my ( $s, $e, $s_state, $s_prov, $s_isp ) =
      ( -1, -1, '无效', '无效', '无效', );
    open my $fh,  '<', $raw;
    open my $fhw, '>', $dst;
    $fhw->autoflush(1);
    print $fhw "s,e,state,prov,isp\n";

    my $all_lines   = 0;
    my $merge_lines = 0;
    while (<$fh>) {
        $all_lines++;
        print "\r$all_lines" if ( $all_lines % 10000 == 0 );

        my ( $s_inet, $e_inet, $n_state, $n_prov, $n_isp ) = extract_loc_line($_);
        next if ( !$s_inet or !$e_inet );

        if (    $s_inet == ( $e + 1 )
            and $n_state eq $s_state
            and $n_prov eq $s_prov
            and $n_isp eq $s_isp )
        {
            $e = $e_inet;
            $merge_lines++;
        }
        else {
            print $fhw "$s,$e,$s_state,$s_prov,$s_isp\n";
            ( $s, $e, $s_state, $s_prov, $s_isp ) =
              ( $s_inet, $e_inet, $n_state, $n_prov, $n_isp );
            $merge_lines = 0;
        }
    }
    print $fhw "$s,$e,$s_state,$s_prov,$s_isp\n";
    close $fhw;
    close $fh;

    return $dst;
}

sub extract_loc_line {
    #ip_c, state, prov, isp
    my ($line) = @_;
    chomp $line;

    my @data = split /,/, $line;
    $_ ||= '未知' for @data;

    $data[1] =~ s/省|市//;
    $data[1] =~ s/(内蒙古|宁夏|新疆|广西|香港).*/$1/;
    $data[2] =~ s/省|市//;

    $data[0] =~ s/^((\d+\.){3})\d+$/${1}0/;
    my $s_inet = unpack( 'N', inet_aton( $data[0] ) );
    my $e_inet = $s_inet + 255;

    return ( $s_inet, $e_inet, @data[1..3] );
}

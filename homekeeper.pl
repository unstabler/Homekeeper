#/usr/bin/env perl
package Homekeeper;
use 5.010;
use strict;
use warnings;

use Carp;
use LWP::UserAgent;
use JSON qw/from_json/;

sub CONFIG_PATH () { sprintf "%s/.homekeeper.json", $ENV{HOME} }
 
sub URL_RESOLVE_PUBLIC_IP   () { "http://resolve-me.tokyohot.club" }

sub CLOUDFLARE_API_PROTOCOL () { "https" } 
sub CLOUDFLARE_API_BASE     () { CLOUDFLARE_API_PROTOCOL . "://api.cloudflare.com/client/v4" }

sub CLOUDFLARE_API_LIST_ZONES    () { ("get", CLOUDFLARE_API_BASE . "/zones?name=%s&status=active&page=1&per_page=20&order=status&direction=desc&match=any") }
sub CLOUDFLARE_API_UPDATE_RECORD () { ("put", CLOUDFLARE_API_BASE . "/zones/%s/dns_record/%s") }

my $CONFIG = {};
my $__UA;

sub UA () {
    if (!$__UA) {
        $__UA = LWP::UserAgent->new;
        $__UA->default_header( "X-Auth-Email" => $CONFIG->{cloudflare_username} );
        $__UA->default_header( "X-Auth-Key"   => $CONFIG->{cloudflare_key} );
        $__UA->default_header( "Content-Type" => "application/json" );
    }

    return $__UA;
}

sub init {
    my $raw_json;
    open my $config_fh, '<', CONFIG_PATH or croak "설정 파일을 열 수 없습니다.";
    $config_raw_json = <$config_fh>;
    close $config_fh;
    
    $CONFIG = from_json $config_raw_json;
}

sub get_public_ip {
    my $res = LWP::UserAgent->new->get(URL_RESOLVE_PUBLIC_IP);
    croak "IP 주소를 확인할 수 없습니다." unless $res->is_success;
    
    return $res->decoded_content;
}

sub cloudflare_list_zones {
    my ($method, $url) = CLOUDFLARE_API_LIST_ZONES; 
    my $domain         = shift;

    $url = sprintf $url, $domain;
    cloudflare_request($method, $url);
}

sub cloudflare_update_record {
    my ($method, $url) = CLOUDFLARE_API_UPDATE_RECORD; 
    my ($zone_id, $ip) = @_;
    
}

sub cloudflare_request {
    my ($method, $url) = @_;
    my $ua = UA;

    my $res = $ua->$method($url);
    if ($res->is_success) {
        return $res;
    } else {
        carp "요청에 실패하였습니다.";
        return;
    }
}

init;


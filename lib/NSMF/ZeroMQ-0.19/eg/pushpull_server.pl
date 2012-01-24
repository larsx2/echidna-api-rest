#!/usr/bin/env perl
use strict;
use ZeroMQ qw(ZMQ_PUSH ZMQ_POLLOUT);

my ($host, $port);

if (@ARGV >= 2) {
    ($host, $port) = @ARGV;
} elsif (@ARGV) {
    if ($ARGV[0] =~ /^([\w\.]+):(\d+)$/) {
        ($host, $port) = ($1, $2);
    } else {
        $host = $ARGV[0];
    }
}
$host ||= '127.0.0.1';
$port ||= 5566;

my $ctxt = ZeroMQ::Context->new();
my $sock = $ctxt->socket(ZMQ_PUSH);
$sock->bind( "tcp://$host:$port" );

my $count = 0;
my $pi = ZeroMQ::PollItem->new();
my $guard = $pi->add( $sock, ZMQ_POLLOUT, sub {
    $count++;
    $sock->send("HELLO? $count");
    $sock->send("WORLD? $count");
warn "sent";
});


while (1) {
    $pi->poll();
    warn "polled";
sleep 1;
}
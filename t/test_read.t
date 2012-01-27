#!/usr/bin/perl 

use strict;
use 5.010;

use lib '../lib';
use Data::Dumper;
use Test::More 'no_plan';
use AnyEvent;

use_ok 'NSMF::Service::Database';

my $settings = {
   driver => 'mysql',
   user   => 'nsmf',
   database => 'nsmf',
   password => 'passw0rd.',
   pool_size => 10,
};

my $db = NSMF::Service::Database->new(dbi => $settings);
my $dbh = $db->fetch;
isa_ok( $dbh, 'AnyEvent::DBI');
$db->return_handle($dbh);

sub profiler {
    my ($cb) = @_;

    my $start_time = AE::now;
    $cb->();
    my $latency = AE::now - $start_time;
    say "This call took  " .$latency. " seconds to return a response.";
}

profiler(sub {
    my $session = $db->search(session => { net_dst_port => 22 })->recv;
    say "Got " .scalar @$session. " sessions";
});

profiler sub {
    my $cv = AE::cv;
    $db->search(session => { net_dst_port => 22 }, sub {
        my $sessions = shift;
        $cv->send(scalar @$sessions);
    });
    say "Got " .$cv->recv. " sessions";
};

exit;

my $events = $db->search(
    event => { 
        id => 1,
    });

say Dumper $events;
exit;
#say Dumper ($events->[0]);
say "Got " .@$events. " events";



my $dbi = $db->fetch;

# default window_size = 100
my $stop = 15;
my $iter = $db->search_iter(session => { net_dst_port => 22 });
while (my $session = $iter->()) {
    isa_ok( $session, 'NSMF::Model::Session');
    last if 0 == $stop--;
}
$stop = 15;
my $iter2 = $db->search_iter(event => { node_id => 1 });
while (my $event = $iter2->()) {
    isa_ok( $event, 'NSMF::Model::Event');
    last if 0 == $stop--;
}

$db->insert(session => { net_dst_total_packets => 1});

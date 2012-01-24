#!/usr/bin/perl 

use strict;
use 5.010;

use lib '../lib';
use Test::More 'no_plan';
use AnyEvent;
use Data::Dumper;

use_ok 'NSMF::Service::Database';
use_ok 'NSMF::Service::Database::DBI';

my $settings = {
    driver => 'mysql',
    user   => 'nsmf',
    database => 'nsmf',
    password => 'passw0rd.',
    pool_size => 10,
    # page => 1000,
};
my $dbi = NSMF::Service::Database::DBI->new($settings);
ok( $dbi->pool_size == 10, "Pool size should be 10");

my $dbh = $dbi->fetch;
isa_ok($dbh, 'AnyEvent::DBI');

my $cv = AE::cv;
$dbh->exec("SELECT SLEEP(0.1)", sub {
    $cv->send("Done");
});
ok("Done" eq $cv->recv, "Should return 'Done' after async query");

my $db = NSMF::Service::Database->new(dbi => $settings);
isa_ok( $db->fetch, 'AnyEvent::DBI');

my $cv2 = AE::cv;
$db->fetch->exec("SELECT SLEEP(0.1)", sub {
    $cv2->send("Done");
});
ok("Done" eq $cv2->recv, "Should return 'Done' after async query");

my $counter = 0;
my $w = AE::timer 0,1,sub { say "Latency: $counter"; $counter += 1 };

my $session = $db->search(session => { net_dst_port => 22 });
#my $iter = $db->search_iter(session => { net_dst_port => 22 });
#my $total = 0;
#while (my $session = $iter->()) {
#    $total += 1;
#}
#say "Got $total sessions by iter!";
say "Got " .$session. " sessions";


#ok( $session->start_time() ~~ '2011-08-25 11:22:09', 'Start time should match');


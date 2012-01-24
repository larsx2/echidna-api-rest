#!/usr/bin/perl

use strict;
use 5.010;

use Foo;
use Result;
use AnyEvent;

use Data::Dumper;
my $db = Foo->new;

my $counter = 0;
my $w; $w = AE::timer 0, 1, sub {
    say "Timing: " .time();
    if ($counter == 10) {
        undef $w;
        exit;
    } else {
        $counter += 1;
    }   
};

my $response = $db->search({ foo => "bar" });
if ($response->is_success) {
    say $response->result;
}

my $rsp = $db->search_sync({ foo => "bar" });
say $rsp;

AE::cv->recv;

my @sessions = NSMF::Model::Session->search(\%criteria);
for my $session (@sessions) {
    say "Session: " .$session->id;
}

my $session_iter = NSMF::Model::Session->search_iter(\%criteria);
while (my $session = $session_iter->next) {
    say "Session: " .$session->id;
}




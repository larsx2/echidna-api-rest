package NSMF::Database;

use strict;
use 5.010;

#use EV;
use AnyEvent;
use Data::Dumper;

sub new {
    bless {}, __PACKAGE__
}

sub search {
    my ($self, $params) = @_;

    for my $source (keys %$params) {
        say "Searching $source";
        say Dumper $params->{$source};
    }
}

sub sleep {
    my ($self, $cb) = @_;
    my $w; $w = AE::timer 3, 0, sub { $cb->(); undef $w };   
}

1;

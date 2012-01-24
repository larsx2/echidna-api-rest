package NSMF::Service::Database::Base;

use strict;
use 5.010;

sub new {
    bless {
        __handle => undef,
    }, shift;
}

sub search { die "Override with custom implementation" }
sub update { die "Override with custom implementation" }
sub insert { die "Override with custom implementation" }
sub delete { die "Override with custom implementation" }

sub validate {
    my ($self, $model, $object) = @_;


}

1;

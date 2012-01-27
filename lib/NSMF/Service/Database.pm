package NSMF::Service::Database;

use strict;
use 5.010;
use Carp;
use Module::Pluggable 
    search_path => 'NSMF::Service::Database', 
    sub_name => 'drivers', 
    except => qr/Base/;

sub new {
    my ($class, $handler, $settings) = @_;
    
    my $driver_package = __PACKAGE__ .'::'. uc $handler;
    say $driver_package;
    croak "Database driver not supported" 
        unless /$driver_package/i ~~ [__PACKAGE__->drivers];
        #unless $handler ~~ ['dbi', 'cassandra', 'mongodb'];

    my $driver_path = "NSMF::Service::Database::" .uc($handler);
    eval qq{require $driver_path}; if ($@) {
        croak "Failed to load $driver_path $@";
    }

    return $driver_path->new($settings);
}

sub _dbi_driver {
    my ($driver) = @_;
    my @drivers = qw(mysql sqlite pgsql);

    croak "DBI Driver not supported" 
        unless $driver ~~ @drivers;
}

1;

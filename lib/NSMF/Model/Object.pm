package NSMF::Model::Object;

use strict;
use 5.010;

use Carp;
use base qw(Class::Accessor);

my $ATTR     = {};
my $REQUIRED = [];

#sub new { bless {}, shift }

sub properties {
    my ($class, $properties) = @_; 

    if (ref $properties eq 'HASH') {
        $class->mk_accessors(keys %$properties);

        $ATTR      = $properties;
        @$REQUIRED = grep { 
                      $_ if ref $properties->{$_} 
                  } keys %$properties;
    } 
    else {
        my @properties = sort keys %{$ATTR};
        return \@properties;
    }   
}

sub metadata { $ATTR }
sub required_properties { $REQUIRED }

sub set {
    my ($self, $method, $arg) = @_;
    
    if (defined $method and exists $ATTR->{$method}) {
        my $type = $ATTR->{$method};
        $type = shift @$type if ref $type eq 'ARRAY';

        eval {
            $self->validate_type($type, $method, $arg);
        }; 
        
        if ($@) {
            croak 'TypeError - ' .$@->{message};
        } else {
            $self->SUPER::set($method, $arg);
        }
    } 
    else {
        carp "Unknown $method called on " .ref $self. " object";
    }
}

sub validate_type {
    my ($self, $type, $key, $value) = @_; 

    given($type) {
        when(/ip/) {  
            croak { message => "IP type expected on '$key' accessor" }
                unless $value ~~ /\A\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\Z/;
        }
        when(/int/) { 
            croak { message => "Integer type expected on '$key' accessor" }
                unless $value ~~ /\A\d+\Z/;
        }   
        when(/text/) {
            croak { message => "Text type expected on '$key' accessor" }
                unless $value ~~ /[a-z0-1.,-_ ]+/i;
        }   
        when(/datetime/) {
            croak { message => "Integer type expected on '$key' accessor" }
                unless $value ~~ /\A\d{4}\-\d{2}\-\d{2} \d{2}\:\d{2}\:\d{2}\Z/;
        }   
    }   

    return 1;
}


1;


package NSMF::Database::Pool::MySQL;

use strict;
use 5.010;

use AnyEvent;
use AnyEvent::DBI;
use Carp;

my $instance;
sub new {
    my ($class, $args) = @_;

    unless ($instance) {
        $instance = bless {
            __pool    => [],
            __counter => 0,       
            __total   => 0,
        }, $class;
    }

    $instance->_setup($args);

    $instance
}

sub _setup {
    my ($self, $args) = @_;

    return unless ref $args;

    $instance->{__total} = $args->{size} // 5;
    croak "Size should be an integer" 
        unless $instance->{__total} ~~ /\d+/;
    
    # dsn
    my $database            = $args->{database} // croak 'Database Not Found';
    $instance->{__user}     = $args->{user}     // croak 'User Not Defined';
    $instance->{__password} = $args->{password} // croak 'Password Not Defined';

    $instance->{__dsn} = "dbi:mysql:$database";

    for (1..$instance->{__total}) {
        push @{ $instance->{__pool} }, 
            new AnyEvent::DBI $instance->{__dsn}, $instance->{__user}, $instance->{__password};
    }
}

sub total {
    my ($self) = @_;
    return $self->{__total};
}

sub fetch {
    my ($self) = @_;

    if ($self->{__counter} == $self->{__total} - 1) {
        $self->{__counter} = 0;
    } else {
        $self->{__counter} += 1;
    }

    return $self->{__pool}->[$self->{__counter}];
}

1;

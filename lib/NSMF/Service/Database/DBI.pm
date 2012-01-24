package NSMF::Service::Database::DBI;

use strict;
use 5.010;

use base qw(NSMF::Service::Database::Base);

use AnyEvent;
use AnyEvent::DBI;
use Carp;

use Data::Dumper;
use NSMF::Model;

my $instance;
sub new {
    my ($class, $args) = @_;

    unless (ref $instance eq __PACKAGE__) {
        $instance = bless {
            __used    => {},
            __pool    => {},
            __free    => [],
            __running => [],
            __counter => 0,       
            __total   => 0,
            __window_size => 1000,
            __return_objects => 0,
        }, $class;

        $instance->_setup($args);
    }

    $instance;
}

sub _setup {
    my ($self, $args) = @_;

    unless (ref $args) {
        warn "Expected ref args";   
    };

    $instance->{__total} = $args->{pool_size} // 10;
    croak "Size should be an integer" 
        unless $instance->{__total} ~~ /\d+/;

    croak "Driver Not Found"   unless defined $args->{driver};
    croak "Database Not Found" unless defined $args->{database};
    croak "User Not Found"     unless defined $args->{user};
    croak "Password Not Found" unless defined $args->{password};
    
    # dsn
    my $driver              = $args->{driver};
    my $database            = $args->{database};
    $instance->{__user}     = $args->{user};    
    $instance->{__password} = $args->{password};

    $instance->{__dsn} = "dbi:$driver:$database";

    for (1..$instance->{__total}) {
        my $dbi = new AnyEvent::DBI 
                      $instance->{__dsn}, 
                      $instance->{__user}, 
                      $instance->{__password};

        $instance->{__pool}->{$dbi->{child_pid}} = $dbi;

        my @pids = keys %{ $instance->{__pool} };

        if (scalar @pids < 1) {
            croak "Error - Failed to create database handlers";
            exit;
        }

        $instance->{__free} = \@pids;
    }
}

sub pool_size {
    my $self = shift;
    keys %{ $self->{__pool} } // die;
}

my $w;
sub fetch {
    my ($self) = @_;

    $w = AE::timer 1, 3, sub {
        my $pids_running   = scalar @{ $self->{__running} };
        my $pids_available = scalar @{ $self->{__free} };
        say "pids available: " .$pids_available;
        say "pids running:   " .$pids_running;
        say Dumper "Free: ", $self->{__free};
        say Dumper "Running: ", $self->{__running};

    };

    my @pids_available = @{ $self->{__free} };
    say "[DEBUG] - Before fetch we have " .scalar @pids_available. " handlers.";

    my $random_idx = int rand @pids_available;
    my $random_pid = $pids_available[$random_idx];

    my $fetch_running = 0;
    unless ($random_pid and $random_pid ~~ @{ $self->{__free} }) {
        say "ALERT: Pid not found in free pool";

        croak "Error - Failed to create handlers" if scalar keys %{ $self->{__pool} } < 1;
        say "Refetching........................";
        $fetch_running = 1;
    }

    my $dbh;
    if ($fetch_running) {
        say "Fetching used pid";
        if ($self->{__counter} == $self->{__total} - 1) {
            $self->{__counter} = 0;
        } else {
            $self->{__counter} += 1;
        }   

        my $used_idx = $self->{__running}->[$self->{__counter}];
        $dbh = $self->{__pool}->{$used_idx};
        say Dumper "Running: ", $self->{__running};
        say "Used PID: " .$dbh->{child_pid};
    } else {
        $dbh = $self->{__pool}->{$random_pid};
    }
    push @{ $self->{__running} }, $dbh->{child_pid};
    splice(@{ $self->{__free} }, $random_idx, 1);

    say "Fetched: " .ref $dbh;

    return $dbh;
}

sub get {
    my $self = shift;
    
    my @pids_pool = sort @{ $self->{__free} };
    say scalar @pids_pool. " handlers available";

    if ($self->{__counter} == $self->{__total} - 1) {
        $self->{__counter} = 0;
    } else {
        $self->{__counter} += 1;
    }   

    my $idx = $pids_pool[$self->{__counter}];
    my $dbh = $self->{__pool}->{$idx};

    say "Selected PID: " .$dbh->{child_pid};
    say "Fetched:      " .ref $dbh;
    say;

    return $dbh;
}

sub pause {
    my ($self, $interval, $cb) = @_;
    
    say "Interval: $interval";
    my $cv; $cv = AE::cv;

    my $dbh = $self->get;

    $cv->cb(sub { 
        my ($cv, $result) = @_;
        $cb->($cv->recv);
    });

    $dbh->exec("SELECT SLEEP(?)", $interval, sub {
        my ($dbh, $rows, $rv) = @_;
        $#_ or die "Failure!";

        $cv->send($rows);
    });

}

sub sleep {
    my ($self, $interval, $cb) = @_;

    $interval //= 10;
    my $dbh = $self->fetch;

    my $w;
    if (ref $dbh eq 'AnyEvent::DBI') {
        undef $w;
        $dbh->exec("SELECT SLEEP(?)", $interval, sub { 
            my ($dbi, $rows, $rv) = @_;

            my $pid = $dbi->{child_pid};
            push @{ $self->{__free} }, $pid
                unless $pid ~~ @{ $self->{__free} };

            my $idx = 0;
            for my $el (@{ $self->{__running} }) {
                last if $el ~~ qr/\A$pid\Z/;
                $idx += 1;
            }

            splice(@{ $self->{__running} }, $idx, 1);

            my $pids_running   = scalar @{ $self->{__running} };
            my $pids_available = scalar @{ $self->{__free} };
            #say "pids available: " .$pids_available;
            #say "pids running:   " .$pids_running;
        
            $cb->(@$rows);
        });

    } else {
        say "--------- DIDNT FOUND HANDLER ---------";
        $w = AE::timer 1, 1, sub {
            say "[SLEEP] Trying.. ";

            $self->sleep($interval, $cb);
        };
    }
}

sub build_query {
    my ($self, $model_type, $criteria, $cb) = @_;

    my $model = $self->_require_model($model_type);
    my $sql   = $self->_mk_query_select($model, $criteria);

    return $sql;
}

sub search {
    my ($self, $model_type, $criteria, $cb) = @_;

    my $dbi   = $self->fetch;
    my $model = $self->_require_model($model_type);
    my $sql   = $self->_mk_query_select($model, $criteria);

    $dbi->exec($sql, sub {
        my ($dbh, $rows, $rv) = @_;
        $#_ or die "Internal Failure $@";

        my $pid = $dbh->{child_pid};
        push @{ $self->{__free} }, $pid
                unless $pid ~~ @{ $self->{__free} };

        my $idx = 0;
        for my $el (@{ $self->{__running} }) {
            last if $el ~~ qr/\A$pid\Z/;
            $idx += 1;
        }

        splice(@{ $self->{__running} }, $idx, 1);

        my @result;
        for my $row (@$rows) {
            push @result, $self->_map_properties($model, $row);
        }
 
        $cb->(@result);
    });
}

sub window_size {
    my ($self, $wsize) = @_;

    if (defined $wsize and $wsize ~~ /\A\d+\Z/) {
        $self->{__window_size} = $wsize;
    } else {
        return $self->{__window_size};
    }
}

sub search_iter {
    my ($self, $model_type, $criteria) = @_;

    my $dbi   = $self->fetch;
    my $model = $self->_require_model($model_type);
    my $sql   = $self->_mk_query($model, $criteria);

    my $page  = $self->window_size // 1000;
    my $rsp   = $self->_do_query($dbi, $sql . " LIMIT 0, ".$self->window_size);

    my @result;
    for my $row (@$rsp) {
        push @result, $self->_map_properties($model, $row);
    }
    
    my $idx    = 0; # array index
    my $offset = 0; # limit offset 
    return sub {
        if ($idx == $page) {
            say "DB Call";
            $offset += $page;
            my $limit = $sql. " LIMIT " .$offset. ", " .$page;
            my $rsp   = $self->_do_query($dbi, $limit);

            splice @result;
            for my $row (@$rsp) {
                push @result, $self->_map_properties($model, $row);
            }

            $idx = 0;
            my $session = $result[$idx];
            $idx += 1;  # this can be omitted using $result[$idx++]

            return $session;
        } else {
            my $session = $result[$idx];
            $idx += 1;

            return $session;
        }
    };
}

sub _require_model {
    my ($self, $model) = @_;

    croak "Invalid search model"
        unless 'NSMF::Model::' .ucfirst($model) ~~ [NSMF::Model->objects];

    my $model_path = 'NSMF::Model::' .ucfirst($model);

    eval qq{require $model_path}; if ($@) {
        croak "Failed to load $model_path " .$@;
    }

    return $model_path;
}

sub _mk_query_select {
    my ($self, $model, $criteria) = @_;
    
    my $table = lc $1 if $model =~ /::(\w+)$/;
    my $query = "SELECT " .join(", ", @{ $model->properties })
              . " FROM " .$table. " " .$self->create_filter($criteria);
}

sub _mk_query_count {
    my ($self, $model, $criteria) = @_;
    
    my $table = lc $1 if $model =~ /::(\w+)$/;
    my $query = "SELECT COUNT(*) FROM " .$table. " " .$self->create_filter($criteria);
}

sub _mk_query_insert {
    my ($self, $object) = @_;

    # Accept Objects only
    # Check for required fields and values
    # insert only no updates
}

sub _do_query {
    my ($self, $dbi, $sql) = @_;

    say "SQL: " .$sql;
    my $cv  = AE::cv;
    $dbi->exec($sql, sub {
        my ($dbh, $rows, $rv) = @_;
        $#_ or croak "Internal Failure $@";
        $cv->send($rows);
    });
    die Dumper $cv->recv;
}

sub _map_properties {
    my ($self, $model, $row) = @_;

    my $hash = {};
    for my $key (@{ $model->properties }) {
        $hash->{$key} = shift @$row;
    }

    if ($self->{__return_object} == 1) {
        return $model->new($hash);
    }
    else {
        return $hash;
    }
}

sub __validate_object {
    my ($self, $model, $object) = @_;

    my @required = grep {
        $_ if ref $model->metadata->{$_} eq 'ARRAY'
    } @{ $model->properties };

    for my $key (keys %{ $model->metadata }) {
        if ($key ~~ @required) {
            my $type  = shift @{ $model->metadata->{$key} };
            my $value = $object->{$key};

            $model->validate_type($type, $key, $value); 
        }
    }
}

sub insert {
    my ($self, $model_type, $data) = @_;

    my $model = $self->_require_model($model_type);
    eval {
        $self->__validate_object($model, $data);
    }; if ($@) {
        warn "DbInsertFailed - " .$@->{message};
    }
}

sub update {
    my ($self, $model, $data) = @_;
}

sub delete {
    my ($self, $model, $data) = @_;
}

sub create_filter
{
    my ($self, $filter) = @_;

    if( ref($filter) ne 'HASH' ) {
        return '';
    }

    return 'WHERE ' . $self->create_filter_from_hash($filter);
}

sub create_filter_from_hash {
    my ($self, $value, $field, $parent_field) = @_;

    if ( defined( $field ) ) {
        $value = $value->{$field};
    }

    my @fields  = keys( %{ $value } );

    return '' if ( @fields == 0 );

    my @where = ();
    my $connect = 'AND';
    my $conditional = '=';

    # build up the search criteria
    for my $f ( @fields ) {
        my $criteria = '';

        given( $f )
        {
            when(/\$eq/) { $conditional = '='; }
            when(/\$ne/) { $conditional = '!='; }
            when(/\$lte/) { $conditional = '<='; }
            when(/\$lt/) { $conditional = '<'; }
            when(/\$gte/) { $conditional = '>='; }
            when(/\$gt/) { $conditional = '>'; }
        }

        if ( ref($value->{$f}) eq 'ARRAY' )
        {
            my $c = $self->create_filter_from_array($value, $f, $field);
            push( @where, $c ) if ( length($c) );
        }
        elsif ( ref($value->{$f}) eq 'HASH' )
        {
            my $c = $self->create_filter_from_hash($value, $f, $field);
            push( @where, $c ) if ( length($c) );
        }
        else {
            my $c = $self->create_filter_from_scalar($value->{$f}, $f, $field, $conditional);
            push( @where, $c ) if ( length($c) );
        }
    }

    return '(' . join(" $connect ", @where) . ')';
}

sub create_filter_from_array {
    my ($self, $value, $field, $parent_field) = @_;

    if ( defined( $field ) ) {
        $value = $value->{$field};
    }

    my @fields = @{ $value };

    return '' if ( @fields == 0 );

    my @where = ();
    my $connect = '';

    given( $field )
    {
        when(/\$nor/) { $connect = 'NOT OR'; $field = undef; }
        when(/\$or/) { $connect = 'OR'; $field = undef; }
        when(/\$and/) { $connect = 'AND'; $field = undef; }
        when(/\$in/) {
            return '(' . $parent_field . ' IN (' . join(",", @{ $value }) . '))';
        }
        when(/\$nin/) {
            return '(' . $parent_field . ' NOT IN (' . join(",", @{ $value }) . '))';
        }
    }

    # build up the search criteria
    for my $f ( @fields ) {
        my $criteria = '';

        if ( ref($f) eq 'ARRAY' )
        {
            my $c = $self->create_filter_from_array($f, $field);
            push( @where, $c ) if ( length($c) );
        }
        elsif ( ref($f) eq 'HASH' )
        {
            my $c = $self->create_filter_from_hash($f, $field);
            push( @where, $c ) if ( length($c) );
        }
    }

    return '(' . join(" $connect ", @where) . ')';
}

sub create_filter_from_scalar {
    my ($self, $value, $field, $parent_field, $conditional) = @_;

    $conditional //= '=';
    $field = $parent_field if ( $field =~ /^\$/ );

    if ( $value =~ m/[^\d]/ )
    {
        return $field . $conditional . $value;
    }

    return $field . $conditional . $value;
}

1;

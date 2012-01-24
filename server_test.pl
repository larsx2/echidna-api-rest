#!/usr/bin/perl -w 

use lib 'lib';
use Mojolicious::Lite;

use AnyEvent;
use EV;

use Data::Dumper;

use NSMF::Service::Database;

app->attr( dbh => sub { 
    NSMF::Service::Database->new(dbi => {
        driver    => 'mysql',
        database  => 'nsmf',
        user      => 'nsmf',
        password  => 'passw0rd.',
        pool_size => 5,
    })
});

get '/' => sub {
    my $self = shift;
    my $dbi = $self->app->dbh->get;

    $dbi->exec("SELECT SLEEP(3)", sub {
        $self->render(text => 'Done'); 
    });
};

get '/pause' => sub {
    my $self = shift;

    $self->render_later;   

    my $rsp = $self->app->dbh->pause(3);
    $self->render(json => $rsp);
};

app->start;

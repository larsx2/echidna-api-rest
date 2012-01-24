#!/usr/bin/perl -w 

use lib 'lib';

use Mojolicious::Lite;
use EV;
use AnyEvent;
use Data::Dumper;
use JSON;

use NSMF::Database;
use NSMF::Database::Pool::MySQL;

app->attr( db => sub { NSMF::Database->new });
app->attr( dbh => sub { 
    NSMF::Database::Pool::MySQL->new({
        database => 'nsmf',
        user     => 'nsmf',
        password => 'passw0rd.',
        size     => 5,
    })
});

get '/' => sub {
    my $self = shift;
    my $dbi = $self->app->dbh->fetch;

    $dbi->exec("SELECT SLEEP(3)", sub {
        $self->render(text => 'Done'); 
    });
};

get '/agent' => sub {
    my $self = shift;
    my $db = $self->app->db;

    my $rsp = $db->get_agents();
    $self->render(json => { result => $rsp});
};

get '/node' => sub {
    my $self = shift;
    my $dbi = $self->app->dbh->fetch;

    my $meta = {
        src  => 'node',
        cols => qw(id agent_id name description type network state updated),
    };
    my $query = "SELECT @{$meta->{cols}} FROM $meta->{src}";
    $dbi->exec($query, sub {
        my ($dbh, $rows, $rv) = @_;
    
        my $result = [];
        for my $row (@$rows) {
            my $response = {};
            my @headers = qw(id agent_id name description type network state updated);
            for my $value (@$row) {
                my $key = shift @headers;
                $response->{$key} = $value;
            }
            push @$result, $response;
        }
        $self->render(json => $result);
    });
};

get '/node/:id' => sub {
    my $self = shift;
    my $dbi = $self->app->dbh->fetch;

    my $id = $self->stash('id');
    $self->render(json => {"error" => "Expected Id as Integer"}) unless $id ~~ /\d+/;

    my $query = "SELECT id, agent_id, name, description, type, network, state, updated FROM node WHERE id = " .$id;
    $dbi->exec($query, sub {
        my ($dbh, $rows, $rv) = @_;

        my $result = [];
        for my $row (@$rows) {
            my $response = {};
            my @headers = qw(id agent_id name description type network state updated);
            for my $value (@$row) {
                my $key = shift @headers;
                $value = "http:\/\/vinself.pronix.no\/agent\/". $value 
                    if $key ~~'agent_id';
                $response->{$key} = $value;
            }
            push @$result, $response;
        }
        $self->render(json => $result);
    });
};

get '/test' => sub {
    my $self = shift;
    my $dbi = $self->app->dbh->fetch;

    $dbi->exec("SELECT * FROM session LIMIT 10", sub {
        my ($dbh, $rows, $rv) = @_;
    
        $self->render(json => $rows);
    });
};

my @resources = qw(session event alert);
for my $resource (@resources) {
    get "/$resource" => sub { shift->render(text => 'Nothing to see here.') };
}

my $clients = [];
websocket '/echo' => sub {
    my $self = shift;

    $self->app->log->debug("Websocket connected.");

    push @$clients, $self->tx;
    $self->on(message => sub {
        my ($self, $message) = @_;

        for my $client (@$clients) {
            $client->send_message(encode_json({ 
                status => "Got " .scalar @$clients. " clients!",
            }));
        }
    });

    $self->on(finish => sub {
        my $self = shift;
        $self->app->log->debug("Websocket disconnected.");
    });
};

app->start;


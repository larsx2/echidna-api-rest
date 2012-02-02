package NSMF::Web::Controller::Session;

use Mojo::Base 'Mojolicious::Controller';
use NSMF::Model::Session;
use AnyEvent;
use Data::Dumper;

sub index {
    my $self = shift;
    my $db   = $self->db;

    Mojo::IOLoop->stream($self->tx->connection)->timeout(300);
    my $criteria = {};
    for my $attr (@{ NSMF::Model::Session->attributes }) {
        if (defined $self->param($attr)) {
            $criteria->{$attr} = $self->param($attr);
        }
    }

    say Dumper $criteria;
    if (keys %$criteria > 0) {
        eval {
            NSMF::Model::Session->validate($criteria);
        }; if ($@) {

            say "Something Failed..";
            $self->render_json({ error => $@ });
            return;
        }

        my $s_time = time;
        $db->search(session => $criteria, sub {
            my $sessions = shift;    

            my $e_time = time;
            my $diff = $e_time - $s_time;
            say "Took: " .$diff;

            #$self->respond_to(
            #    json => { json => { "total" => $diff } },
            #    any  => { json => $sessions },
            #);
            $self->render_json({took=>$diff});
        });
    }
    else {
        $db->count(session => sub {
            my $count = shift;

            $self->respond_to(
                json => sub { 
                    $self->render_json({total => $count})
                },
                xml  => { text => "<total>" .$count->[0]. "</total>" }
            );
        });
    }
}

sub by_id {
    my $self = shift;

    my $db = $self->app->db;
    my $id = $self->param('id') || '';

    return $self->render(json => {
               error => 'Invalid Id for Session Resource.'
           }) unless $id ~~ /\d+/;
    
    $db->search(session => { id => $id }, sub {
        my $session = shift;  

        $self->respond_to(
            json => { json => $session },
            any  => { json => $session },
        );
    });

}

sub add { 
    my $self = shift;
    $self->render(
        status => 501,
        json => { status => 'This method has not been implemented yet' }
    );
}

sub update {
    my $self = shift;
    $self->render(
        status => 501,
        json => { status => 'This method has not been implemented yet' }
    );
}

sub delete {
    my $self = shift;
    $self->render(
        status => 501,
        json => { status => 'This method has not been implemented yet' }
    );
}


1;

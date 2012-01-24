package NSMF::Server::Web::Event;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;

    $self->render(text => 'Hola.');
}

sub by_id {
    my $self = shift;

    my $id = $self->param('id') || '';
    $self->redirect_to('/') unless $id ~~ /\d+/;

    $self->render(json => { id => $id, type => 'event' });
}

1;

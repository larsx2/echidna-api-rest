package NSMF::Server::Web::Session;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    my $db   = $self->db;

    $db->sleep(3, sub {
        $self->render(json => { status => 'Done' });
    });
    #$db->fetch->exec("SELECT SLEEP(3)", sub { $self->render(text => 'Done') });
}

sub by_id {
    my $self = shift;

    my $db = $self->db;
    my $id = $self->param('id') || '';

    return $self->render(json => {
               error => 'Invalid Id for Session Resource.'
           }) unless $id ~~ /\d+/;
    
    #my $query = $db->build_query(session => { id => $id });
    #say "SQL: " .$query;
    #$db->fetch->exec($query, sub {
    #    my ($dbi, $rows, $rv) = @_;
    #    $#_ or die "Failure $@";
    #    $self->respond_to(
    #        json => { json => @$rows },
    #    );
    #});
    my $cb = sub {
        my (@sessions) = @_;

        $self->render(json => @sessions);
    };

    $db->search(session => { id => $id }, \&$cb);

    #$db->search(session => { id => $id }, sub {
    #    my (@sessions) = @_;

     #   $self->respond_to(
    #        json => { json => @sessions },
    #    );
    #});
}

sub add { 
    my $self = shift;
    $self->render(json => { status => 'Done' }); 
}

sub update {
    my $self = shift;
    $self->render(json => { status => 'Done' }); 
}

sub delete {
    my $self = shift;
    $self->render(json => { status => 'Done' }); 
}


1;

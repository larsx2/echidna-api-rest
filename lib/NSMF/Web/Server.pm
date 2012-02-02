package NSMF::Web::Server;
use Mojo::Base 'Mojolicious';

use NSMF::Service::Database;


sub startup {
    my $self = shift;

    $self->helper(db => sub {
        NSMF::Service::Database->new(
            dbi => {
                driver    => 'mysql',
                user      => 'nsmf',
                database  => 'nsmf',
                password  => 'passw0rd.',
                pool_size => 2,
                debug => 1,
            });

        
    });
    $self->secret('NSMF Echidna Secret Key');

    my $router = $self->routes;

    $router->namespace('NSMF::Web::Controller');
    $router->get('/')->to('main#index')->name('index');
    
    my @resources = qw(
        session
        event
        agent
        node
    );
    for my $resource (@resources) {
        my $uri = "/" .$resource;
        my $route = $router->under($uri);
        $route->get('/')->to($resource .'#index');
        $route->get('/:id', { id => qr/\d+/ })->to($resource .'#by_id');
        $route->post('/')->to($resource .'#add');
        $route->put('/:id', { id => qr/\d+/ })->to($resource .'#update');
        $route->delete('/:id', { id => qr/\d+/ })->to($resource .'#delete');
    }

}

1;

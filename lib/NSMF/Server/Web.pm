package NSMF::Server::Web;
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
                pool_size => 10,
            });
    });

    $self->secret('NSMF Echidna Secret Key');

    my $router = $self->routes;

    $router->get('/')->to('main#index')->name('index');
    
    # session 
    my $resource = $router->under('/session');
    $resource->get('/')->to('session#index');
    $resource->get('/:id', { id => qr/\d+/ })->to('session#by_id');
    $resource->post('/')->to('session#add');
    $resource->put('/:id', { id => qr/\d+/ })->to('session#update');
    $resource->delete('/:id', { id => qr/\d+/ })->to('session#delete');

}

1;

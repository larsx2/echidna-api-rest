package Mojolicious::Plugin::NetModel;
use Mojo::Base 'Mojolicious::Plugin';

use File::Spec;
use lib File::Spec->catdir('..', '..', 'lib');

sub register {
    my ($self, $app, $conf) = @_;

    $app->attr(db => sub {
        
    });
}

1;

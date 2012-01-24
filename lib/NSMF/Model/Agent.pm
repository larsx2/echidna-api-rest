package NSMF::Model::Agent;

use strict;
use 5.010;

__PACKAGE__->properties({
    id            => ['int'],
    name          => ['text'],
    password      => ['text'],
    description   => 'text',
    ip            => ['decimal'],
    state         => ['text'],
    updated       => ['text'],
});

1;

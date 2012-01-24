package NSMF::Model::Node;

use strict;
use 5.010;

__PACKAGE__->properties({
    id          => ['int'],
    agent_id    => ['int'],
    name        => ['text'],
    password    => ['text'],
    type        => ['text'],
    description => 'text',
    network     => ['text'],
    state       => ['text'],
    updated     => ['text'],
});

1;

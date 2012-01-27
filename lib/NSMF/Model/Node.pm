package NSMF::Model::Node;

use strict;
use 5.010;

__PACKAGE__->properties({
    id          => ['int'],
    name        => ['text'],
    type        => ['text'],
    agent_id    => ['int'],
    password    => ['text'],
    network     => ['text'],
    state       => ['text'],
    updated     => ['text'],
    description => 'text',
});

1;

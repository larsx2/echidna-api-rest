use strict;
use warnings;
use 5.10.0;

use ZeroMQ qw/:all/;

my $context = ZeroMQ::Context->new();

my $subscriber = $context->socket(ZMQ_SUB);
$subscriber->connect('tcp://localhost:5556');

$subscriber->setsockopt(ZMQ_SUBSCRIBE, '');

while (1) {
    my $string = $subscriber->recv->data;
    say "Got " .$string;
}

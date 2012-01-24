use strict;
use warnings;
use 5.10.0;

use ZeroMQ qw/:all/;

my $context = ZeroMQ::Context->new();
my $publisher = $context->socket(ZMQ_PUB);
$publisher->bind('tcp://*:5556');
$publisher->bind('ipc://weather.ipc');

while (1) {
    $publisher->send("Hello");
    say "Sending Hello";
    sleep 1;
}

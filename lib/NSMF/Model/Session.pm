package NSMF::Model::Session;

use strict;
use 5.010;

use base qw(NSMF::Model::Object);

__PACKAGE__->properties({
    # required
    id                    => ['int'],
    node_id               => ['int'],
    time_start            => ['datetime'],
    time_end              => ['datetime'],
    net_src_ip            => ['ip'],
    net_src_port          => ['int'],
    net_dst_ip            => ['ip'],
    net_dst_port          => ['int'],
    net_protocol          => ['int'],
    net_src_total_bytes   => ['int'],
    net_dst_total_bytes   => ['int'],
    net_src_total_packets => ['int'],
    net_dst_total_packets => ['int'],

    # optional
    timestamp     => 'timestamp',
    time_duration => 'text',
    net_version   => 'int',
    net_src_flags => 'int',
    net_dst_flags => 'int',
    data_filename => 'text',
    data_offset   => 'int',
    data_length   => 'int',
    meta          => 'any',
});

1;

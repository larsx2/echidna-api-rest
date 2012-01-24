#!/usr/bin/env perl
use strict;
use 5.010;

use lib '../lib';
use Test::More 'no_plan';

use_ok 'NSMF::Common::Registry';
use_ok 'NSMF::Server::DB::MYSQL';

my $db = NSMF::Server::DB::MYSQL->instance();
isa_ok($db, 'NSMF::Server::DB::MYSQL');


my $settings  = {
     type => 'mysql',
     host => 'localhost',
     port => 3306,
     name => 'nsmf',
     user => 'nsmf',
     pass => 'passw0rd.',
};
say $settings;
$db->create($settings);
say Dumper $db;


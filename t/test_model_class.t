#!/usr/bin/perl

use strict;
use 5.010;

use lib '../lib';

use Data::Dumper;
use NSMF::Model::Session;
my $path = "NSMF::Model::Session";

say Dumper $path->attributes;

my $session = NSMF::Model::Session->new({ id => 12 });
say $session->get('id');

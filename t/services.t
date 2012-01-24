#!/usr/bin/perl

use strict;
use 5.010;

use Test::More 'no_plan';

use lib '../lib';

use_ok 'NSMF::Service::Database';
say NSMF::Service::Database->drivers;

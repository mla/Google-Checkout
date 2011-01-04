#!perl -T

use strict;
use Test::More tests => 1;

BEGIN {
	use_ok( 'Google::Checkout::General::GCO' );
}

diag( "Testing GCO $Google::Checkout::General::GCO::VERSION, Perl $], $^X" );


#!perl

use Test::More qw/ no_plan /;

use Google::Checkout::Command::GCOCommand;
use Google::Checkout::General::GCO;
use Google::Checkout::General::Util qw/ is_gco_error /;

my $gco = Google::Checkout::General::GCO->new;

my $c = Google::Checkout::Command::GCOCommand->new;
ok($c, 'instantiate with no params');

eval { $c->to_xml };
ok($@, 'gco parameter required');

my $rv = $c->to_xml(gco => $gco);
ok(is_gco_error($rv), 'order number is required');

$c->set_order_number(12);
is($c->get_order_number, 12, 'get/set order number');

$rv = $c->to_xml(gco => $gco);
diag($rv);

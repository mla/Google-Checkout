package Google::Checkout::XML::CommandXmlWriter;

#--
#-- Writes a generic command XML.
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/make_xml_safe/;

use Google::Checkout::XML::Writer;
our @ISA = qw/Google::Checkout::XML::Writer/;

sub new 
{
  my ($class, %args) = @_;

  delete $args{root};

  my $self = $class->SUPER::new(%args);

  $self->add_element(name => $args{command}->get_name,
                     attr => [xmlns => $args{gco}->reader()->get(
                              Google::Checkout::XML::Constants::XML_SCHEMA),
                              Google::Checkout::XML::Constants::ORDER_NUMBER => 
                                $args{command}->get_order_number]);

  if ($args{command}->get_amount)
  {
    $self->add_element(close => 1,
                       name => Google::Checkout::XML::Constants::AMOUNT, 
                       data => $args{command}->get_amount,
                       attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY => 
                                $args{gco}->reader()->get(
                                  Google::Checkout::XML::Constants::CURRENCY_SUPPORTED)]);
  }

  return bless $self => $class;
}

1;

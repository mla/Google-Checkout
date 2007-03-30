package Google::Checkout::XML::CheckoutXmlWriter;

#--
#-- <checkout-shopping-cart>...</checkout-shopping-cart>
#--

use strict;
use warnings;

use Google::Checkout::XML::Constants;
use Google::Checkout::General::Util qw/make_xml_safe format_tax_rate/;

use Google::Checkout::XML::Writer;
our @ISA = qw/Google::Checkout::XML::Writer/;

sub new 
{
  my ($class, %args) = @_;

  delete $args{root};

  my $self = $class->SUPER::new(%args);

  my $xml_schema = '';
  my $currency_supported = '';

  if ($args{gco}->reader()) {

    my $reader = $args{gco}->reader();

    $xml_schema = $reader->get(Google::Checkout::XML::Constants::XML_SCHEMA);
    $currency_supported = $reader->get(Google::Checkout::XML::Constants::CURRENCY_SUPPORTED);

  } else {

    $xml_schema = $args{gco}->{__xml_schema};
    $currency_supported = $args{gco}->{__currency_supported};

  }

  $self->add_element(name => Google::Checkout::XML::Constants::CHECKOUT_ROOT,
                     attr => [xmlns => $xml_schema]);

  if ($args{cart})
  {
    $self->add_element(name => Google::Checkout::XML::Constants::SHOPPING_CART);

    #--
    #-- If the cart has an expiration, add it
    #--
    if ($args{cart}->get_expiration())
    {
      $self->add_element(name => Google::Checkout::XML::Constants::EXPIRATION);
      $self->add_element(name => Google::Checkout::XML::Constants::GOOD_UNTIL, 
                         data => $args{cart}->get_expiration(), close => 1);
      $self->close_element();
    }

    #--
    #-- If we have any merchant private data, add it
    #--
    if ($args{cart}->get_private())
    {
      my @private_data = @{$args{cart}->get_private()};

      $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_PRIVATE_DATA) 
        if @private_data;

      for my $note (@private_data)
      {
        $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_PRIVATE_NOTE, 
                           data => $note, close => 1);
      }
      $self->close_element() if @private_data;
    }

    my @items = @{$args{cart}->get_items()};

    $self->add_element(name => Google::Checkout::XML::Constants::ITEMS) if @items;

    for (@items)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::ITEM);
        $self->add_element(name => Google::Checkout::XML::Constants::ITEM_NAME, 
                           data => $_->get_name(), close => 1);
        $self->add_element(name => Google::Checkout::XML::Constants::ITEM_DESCRIPTION,
                           data => $_->get_description(), close => 1);
        $self->add_element(name => Google::Checkout::XML::Constants::ITEM_PRICE,
                           data => $_->get_price(), close => 1,
                           attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY => 
                                    $currency_supported]);
        $self->add_element(name => Google::Checkout::XML::Constants::QUANTITY,
                           data =>$_->get_quantity(), close => 1);

        if ($_->get_private())
        {
          my @private_data = @{$_->get_private()};

          $self->add_element(name => Google::Checkout::XML::Constants::ITEM_PRIVATE_DATA) 
            if @private_data;

          for my $note (@private_data)
          {
            $self->add_element(name => Google::Checkout::XML::Constants::ITEM_PRIVATE_NOTE, 
                               data => $note, close => 1);
          }
          $self->close_element() if @private_data;
        }

        $self->add_element(name => Google::Checkout::XML::Constants::TAX_TABLE_SELECTOR,
                           data => $_->get_tax_table_selector(), close => 1)
          if $_->get_tax_table_selector();

      $self->close_element();
    }

    $self->close_element() if @items;

    $self->close_element();
  }

  #--
  #-- Add merchant checkout flow
  #--
  $self->add_element(name => Google::Checkout::XML::Constants::CHECKOUT_FLOW);
  $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_CHECKOUT_FLOW);

  my $checkout_flow = $args{cart}->get_checkout_flow();

  if ($checkout_flow)
  {
    my $edit_cart_url = $checkout_flow->get_edit_cart_url;
    if ($edit_cart_url)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::EDIT_CART_URL,
                         data => make_xml_safe($edit_cart_url), close => 1);
    }

    my $continue_shopping_url = $checkout_flow->get_continue_shopping_url;
    if ($continue_shopping_url)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::CONTINUE_SHOPPING_URL,
                         data => make_xml_safe($continue_shopping_url), close => 1);
    }

    my $buyer_phone = $checkout_flow->get_buyer_phone;
    if ($buyer_phone)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::BUYER_PHONE_NUMBER,
                         data => "true", close => 1);
    }

    my $analytics_data = $checkout_flow->get_analytics_data;
    if ($analytics_data) {
      $self->add_element(name => Google::Checkout::XML::Constants::ANALYTICS_DATA,
                         data => $analytics_data, close => 1);
    }

    #--
    #-- Add tax tables
    #--
    $self->_add_tax_tables($checkout_flow);

    #--
    #-- Add merchant calculations
    #--
    $self->_add_merchant_calculations($checkout_flow);
  }

  my $shippings = $checkout_flow ? $checkout_flow->get_shipping_method() : undef;

  if ($shippings)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::SHIPPING_METHODS) 
      if @{$shippings};

    for my $shipping (@{$shippings})
    {
      #--
      #-- We should also consider raise an error because price is required
      #--
      my $price = $shipping->get_price();
         $price = 0 unless defined $price;

      $self->add_element(name => $shipping->get_name(),
                         attr => [Google::Checkout::XML::Constants::NAME, 
                                  $shipping->get_shipping_name()]);
      $self->add_element(name => Google::Checkout::XML::Constants::PRICE,
                         data => $price, close => 1,
                         attr => [Google::Checkout::XML::Constants::ITEM_CURRENCY =>
                                  $currency_supported]);

      my $restriction = $shipping->get_restriction();
      if ($restriction)
      {
        $self->add_element(name => Google::Checkout::XML::Constants::SHIPPING_RESTRICTIONS);
     
        my $as = $restriction->get_allowed_state();
        my $az = $restriction->get_allowed_zip();
        my $ac = $restriction->get_allowed_country_area();

        my $has_allowed = (defined $as && @{$as}) ||
                          (defined $az && @{$az}) ||
                          (defined $ac && @{$ac});

        my $es = $restriction->get_excluded_state();
        my $ez = $restriction->get_excluded_zip();
        my $ec = $restriction->get_excluded_country_area();

        my $has_excluded = (defined $es && @{$es}) ||
                           (defined $ez && @{$ez}) ||
                           (defined $ec && @{$ec});

        $self->add_element(name => Google::Checkout::XML::Constants::ALLOWED_AREA) 
          if $has_allowed;
        $self->_handle_allow($as, $az, $ac);
        $self->close_element() if $has_allowed;

        $self->add_element(name => Google::Checkout::XML::Constants::EXCLUDED_AREA) 
          if $has_excluded;
        $self->_handle_exclude($es, $ez, $ec);
        $self->close_element() if $has_excluded;

        $self->close_element();

      } #-- END if ($restriction)

      $self->close_element();

    } #-- END for
  }

  return bless $self => $class;
}

#-- PRIVATE --#

sub _handle_allow
{
  my ($self, $as, $az, $ac) = @_;

  if (defined $as)
  {
    $self->_add_allow_exclude(Google::Checkout::XML::Constants::US_STATE, 
                              Google::Checkout::XML::Constants::STATE, $_) for (@{$as});
  }

  if (defined $az)
  {
    $self->_add_allow_exclude(Google::Checkout::XML::Constants::US_ZIP_AREA, 
                              Google::Checkout::XML::Constants::US_ZIP_PATTERN, $_) for (@{$az});
  }

  if (defined $ac)
  {
    for (@{$ac})
    {
      $self->add_element(name => Google::Checkout::XML::Constants::US_COUNTRY_AREA,
                         attr => [Google::Checkout::XML::Constants::COUNTRY_AREA, $_], close => 1);
    }
  }
}

sub _handle_exclude
{
  my ($self, $es, $ez, $ec) = @_;

  if (defined $es)
  {
    $self->_add_allow_exclude(Google::Checkout::XML::Constants::US_STATE, 
                              Google::Checkout::XML::Constants::STATE, $_) for (@{$es});
  }

  if (defined $ez)
  {
    $self->_add_allow_exclude(Google::Checkout::XML::Constants::US_ZIP_AREA, 
                              Google::Checkout::XML::Constants::US_ZIP_PATTERN, $_) for (@{$ez});
  }

  if (defined $ec)
  {
    for (@{$ec})
    {
      $self->add_element(name => Google::Checkout::XML::Constants::US_COUNTRY_AREA,
                         attr => [Google::Checkout::XML::Constants::COUNTRY_AREA, $_], close => 1);
    }
  }
}

sub _add_allow_exclude
{
  my ($self, $pname, $cname, $data) = @_;

  $self->add_element(name => $pname);
  $self->add_element(name => $cname, data => $data, close => 1);
  $self->close_element();
}

sub _add_tax_tables
{
  my ($self, $mcf) = @_;

  return unless $mcf;

  my $tables = $mcf->get_tax_table;

  return unless $tables;

  $self->add_element(name => Google::Checkout::XML::Constants::TAX_TABLES, 
                     attr => [Google::Checkout::XML::Constants::MERCHANT_CALCULATED => 
                              $mcf->get_merchant_calculation ? 'true' : 'false']) 
    if @$tables;

  my ($default_tables, $alternate_tables) = $self->_get_alternate_default($tables);

  if (ref $default_tables && @$default_tables)
  {
    #--
    #-- Only allow one default tax table
    #--
    $self->add_element(name => Google::Checkout::XML::Constants::DEFAULT_TAX_TABLE);
    $self->add_element(name => Google::Checkout::XML::Constants::TAX_RULES);

    my $rules = $default_tables->[0]->get_tax_rules;
    if ($rules)
    {
      for my $rule (@$rules)
      {
        $self->_write_tax_area($rule, 1);
      }
    }

    $self->close_element();
    $self->close_element();
  }

  if (@$alternate_tables)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::ALTERNATE_TAX_TABLES);
    for my $atable (@$alternate_tables)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::ALTERNATE_TAX_TABLE,
                         attr => [Google::Checkout::XML::Constants::STANDALONE => $atable->get_standalone,
                                  Google::Checkout::XML::Constants::NAME       => $atable->get_name]);

      $self->add_element(name => Google::Checkout::XML::Constants::ALTERNATE_TAX_RULES);

      my $rules = $atable->get_tax_rules;

      if ($rules)
      {
        for my $rule (@$rules)
        {
          $self->_write_tax_area($rule, 0);
        }
      }

      $self->close_element();
      $self->close_element();
    }
    $self->close_element();
  }

  $self->close_element() if @$tables;
}

sub _write_tax_area
{
  my ($self, $table, $is_default) = @_;

  my $area = $table->get_area;

  return unless $area && @$area;

  if ($is_default)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::DEFAULT_TAX_RULE);
    $self->add_element(name => Google::Checkout::XML::Constants::SHIPPING_TAXED, close => 1,
                       data => $table->require_shipping_tax);
  }
  else
  {
    $self->add_element(name => Google::Checkout::XML::Constants::ALTERNATE_TAX_RULE); 
  }

  $self->add_element(name => Google::Checkout::XML::Constants::RATE, close => 1,
                     data => format_tax_rate($table->get_rate));
  $self->add_element(name => Google::Checkout::XML::Constants::TAX_AREA);

  for my $ar (@$area)
  {
    my $state = $ar->get_state;
    if ($state)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::US_STATE) if @$state;
      for my $s (@$state)
      {
        $self->add_element(name => Google::Checkout::XML::Constants::STATE, data => $s, close => 1);
      }
      $self->close_element() if @$state;
    }

    my $zip = $ar->get_zip;
    if ($zip)
    {
      $self->add_element(name => Google::Checkout::XML::Constants::US_ZIP_AREA) if @$zip;
      for my $z (@$zip)
      {
        $self->add_element(name => Google::Checkout::XML::Constants::US_ZIP_PATTERN, 
                           data => $z, close => 1);
      }
      $self->close_element() if @$zip;
    }

    my $country = $ar->get_country;
    if ($country)
    {
      for my $c (@$country)
      {
        $self->add_element(name => Google::Checkout::XML::Constants::US_COUNTRY_AREA,
                           attr => [Google::Checkout::XML::Constants::COUNTRY_AREA, $c], close => 1);
      }
    }
  } 

  $self->close_element();
  $self->close_element(); 
}

sub _get_alternate_default
{
  my ($self, $tables) = @_;

  my @dst_tables = ([], []);

  for my $table ($tables ? @$tables : ())
  {
    push(@{$dst_tables[$table->is_default ? 0 : 1]}, $table);
  }

  return @dst_tables;
}

sub _add_merchant_calculations
{
  my ($self, $mcf) = @_;

  my $calculation = $mcf->get_merchant_calculation;

  return unless $calculation;

  $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_CALCULATION);

  if ($calculation->get_url)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::MERCHANT_CALCULATION_URL,
                       data => $calculation->get_url, close => 1);
  }

  if ($calculation->get_coupons)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::ACCEPT_MERCHANT_COUPONS,
                       data => $calculation->get_coupons, close => 1);
  }

  if ($calculation->get_certificates)
  {
    $self->add_element(name => Google::Checkout::XML::Constants::ACCEPT_GIFT_CERTIFICATES,
                       data => $calculation->get_certificates, close => 1);
  }

  $self->close_element();

}

1;

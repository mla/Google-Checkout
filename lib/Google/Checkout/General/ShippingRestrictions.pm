package Google::Checkout::General::ShippingRestrictions;

=head1 NAME

Google::Checkout::General::ShippingRestrictions

=head1 SYNOPSIS

  use Google::Checkout::XML::Constants;
  use Google::Checkout::General::ShippingRestrictions;
  use Google::Checkout::General::MerchantCalculatedShipping;

  my $restriction = Google::Checkout::General::ShippingRestrictions->new(
                    allowed_zip           => ["94*"],
                    excluded_zip          => ["90*"],
                    excluded_country_area => [Google::Checkout::XML::Constants::FULL_50_STATES]);

  my $custom_shipping = Google::Checkout::General::MerchantCalculatedShipping->new(
                        price         => 45.99,
                        restriction   => $restriction,
                        shipping_name => "Custom shipping");

=head1 DESCRIPTION

This module is used to define shipping address-filters or restrictions which can then
be added as part of a shipping method.

=over 4

=item new HASH

Constructor. Takes a hash as its argument with the following keys: 
ALLOWED_STATE, array reference of allowed states; ALLOWED_ZIP, array
reference of allowed zip code; ALLOWED_COUNTRY_AREA, array reference
of allowed country area; EXCLUDED_STATE, array reference of excluded
states; EXCLUDED_ZIP, array reference of excluded zip codes, 
EXCLUDED_COUNTRY_AREA, array reference of excluded country area. ALLOWED_ALLOW_US_PO_BOX,
true or false to enable PO Box addresses. ALLOWED_WORLD_AREA true or false to enable international shipping.
ALLOWED_POSTAL_AREA, array reference of allowed countries. For
ALLOWED_ZIP and EXCLUDED_ZIP, it's possible to use the wildcard 
operator (*) to specify a range of zip codes as in "94*" for all zip
codes starting with "94".

=item get_allowed_state 

Returns the allowed states (array reference).

=item add_allowed_state STATE

Adds another allowed state.

=item get_allowed_zip 

Returns the allowed zip codes (array reference).

=item add_allowed_zip ZIP

Adds another allowed zip code. Zip code can
have the wildcard operator to specify a range
of zip codes.

=item get_allowed_country_area

Returns the allowed country area (array reference).

=item add_allowed_country_area AREA

Adds another allowed country area. Currently, the 
only supported country area is C<Google::Checkout::XML::Constants::FULL_50_STATES>.

=item get_excluded_state

Returns the excluded states (array reference).

=item add_excluded_state STATE

Adds another excluded state.

=item get_excluded_zip

Returns the excluded zip codes (array reference).

=item add_excluded_zip ZIP

Adds another excluded zip code. Zip code can
have the wildcard operator to specify a range
of zip codes.

=item add_excluded_country_area AREA

Adds another excluded country area. Currently, the
only supported country area is C<Google::Checkout::XML::Constants::FULL_50_STATES>.

=item add_allowed_allow_us_po_box BOOLEAN

Set weather or not US PO Box addresses are allowed

=item get_allowed_allow_us_po_box

Returns true, false, or undefined if this has not been set

=item add_allowed_world_area BOOLEAN

Enables international shipping by setting the world_area value

=item get_allowed_world_area

Returns true or undefined

=back

=cut

=head1 COPYRIGHT

Copyright 2006 Google. All rights reserved.

=cut

#--
#-- <shipping-restrictions> ... </shipping-restrictions>
#--

use strict;
use warnings;

sub new 
{
  my ($class, %args) = @_;

  my $self = {};

  #--
  #-- Allowed area
  #--
  if($args{allowed_allow_us_po_box})
  {
    $self->{allowed_allow_us_po_box} = $args{allowed_allow_us_po_box} eq 'true' ? 'true' : 'false';
  }

  if(($args{allowed_world_area})&&($args{allowed_world_area} eq 'true'))
  {
    $self->{allowed_world_area} = 'true';
  }

  if($args{allowed_state})
  {
    for (@{$args{allowed_state}})
    {
      s/\s//g;
      push(@{$self->{allowed_state}}, $_);
    }
  }

  if ($args{allowed_zip})
  {
    for (@{$args{allowed_zip}})
    {
      #--
      #-- Clean up. Even an extra space cause GCO to error out!
      #--
      s/\s//g;
      push(@{$self->{allowed_zip}}, $_); 
    }
  }

  if ($args{allowed_country_area})
  {
    push(@{$self->{allowed_country_area}}, $_) 
      for (@{$args{allowed_country_area}});
  }

  #--
  #-- Excluded area
  #--
  if ($args{excluded_state})
  {
    push(@{$self->{excluded_state}}, $_) for (@{$args{excluded_state}});
  }

  if ($args{excluded_zip})
  {
    push(@{$self->{excluded_zip}}, $_) for (@{$args{excluded_zip}});
  }

  if ($args{excluded_country_area})
  {
    push(@{$self->{excluded_country_area}}, $_) 
      for (@{$args{excluded_country_area}});
  }

  return bless $self => $class;
}

sub get_allowed_world_area
{
  my ($self) = @_;

  return $self->{allowed_world_area}; 
}

sub get_allowed_allow_us_po_box
{
  my ($self) = @_;

  return $self->{allowed_allow_us_po_box}; 
}

sub get_allowed_state        
{ 
  my ($self) = @_;

  return $self->{allowed_state}; 
}

sub get_allowed_zip          
{ 
  my ($self) = @_;

  return $self->{allowed_zip};
}

sub get_allowed_country_area 
{ 
  my ($self) = @_;

  return $self->{allowed_country_area}; 
}

sub get_excluded_state        
{ 
  my ($self) = @_;

  return $self->{excluded_state};
}

sub get_excluded_zip
{ 
  my ($self) = @_;

  return $self->{excluded_zip};
}

sub get_excluded_country_area 
{ 
  my ($self) = @_;

  return $self->{excluded_country_area}; 
}

sub add_allowed_world_area
{
  my ($self, $data) = @_;

  if ((defined $data)&&($data eq 'true')) {
    $self->{allowed_world_area} = 'true';
  } else {
    $self->{allowed_world_area} = undef;
  }
}

sub add_allowed_allow_us_po_box
{
  my ($self, $data) = @_;

  $self->{allowed_allow_us_po_box} = ($data eq 'true' ? 'true' : 'false') if defined $data; 
}

sub add_allowed_state        
{ 
  my ($self, $data) = @_;

  $data =~ s/\s//g;

  push(@{$self->{allowed_state}}, $data) if defined $data;
}

sub add_allowed_zip          
{
  my ($self, $data) = @_;

  $data =~ s/\s//g;
 
  push(@{$self->{allowed_zip}}, $data) if defined $data;
}

sub add_allowed_country_area 
{
  my ($self, $data) = @_;
 
  push(@{$self->{allowed_country_area}}, $data) if defined $data;
}

sub add_excluded_state        
{ 
  my ($self, $data) = @_;

  push(@{$self->{excluded_state}}, $data) if defined $data;
}

sub add_excluded_zip          
{ 
  my ($self, $data) = @_;

  $data =~ s/\s//g;

  push(@{$self->{excluded_zip}}, $data) if defined $data;
}

sub add_excluded_country_area 
{ 
  my ($self, $data) = @_;

  push(@{$self->{excluded_country_area}}, $data) if defined $data;
}

1;

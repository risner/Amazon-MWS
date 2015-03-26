package Amazon::MWS::XML::Response::OrderReport;

use utf8;
use strict;
use warnings;
use DateTime;
use DateTime::Format::ISO8601;
use Data::Dumper;
use Amazon::MWS::XML::Response::OrderReport::Item;
use Amazon::MWS::XML::Address;
use Moo;
use MooX::Types::MooseLike::Base qw(HashRef ArrayRef);
use namespace::clean;

=head1 NAME

Amazon::MWS::XML::Response::OrderReport

=head1 DESCRIPTION

Class to handle the xml structures returned by the C<GetReport> with type
C<OrderReport>.

The constructor is meant to be called by L<Amazon::MWS::Uploader> when
C<get_order_reports> is called. A list of objects of this class will be
returned.

=head1 SYNOPSIS

 my $order = Amazon::MWS::XML::Response::OrderReport->new(struct => $struct);
 my @items = $order->items;

=head1 ACCESSORS

=head2 struct

Mandatory. Must be an hashref.

=head2 order_number

Our order ID. Read-write.

=head2 shipping_address

An L<Amazon::MWS::XML::Address> instance, lazily built.

=head2 billing_address

An L<Amazon::MWS::XML::Address> instance, lazily built.

=cut

has struct => (is => 'ro', isa => HashRef, required => 1);
has order_number => (is => 'rw');
has shipping_address => (is => 'lazy');
has billing_address => (is => 'lazy');

sub _build_shipping_address {
    my $self = shift;
    my $data = $self->struct->{FulfillmentData};
    # unclear if we want to check the FulfillmentMethod
    if (my $address = $data->{Address}) {
        return Amazon::MWS::XML::Address->new(%$address);
    }
    return undef;
}

sub _build_billing_address {
    my $self = shift;
    my $data = $self->struct->{BillingData};
    if (my $address = $data->{Address}) {
        return Amazon::MWS::XML::Address->new(%$address);
    }
    return undef;
}

has _items_ref => (is => 'lazy');

sub _build__items_ref {
    my $self = shift;
    my @items;
    if (my $list = $self->struct->{Item}) {
        foreach my $item (@$list) {
            my $obj = Amazon::MWS::XML::Response::OrderReport::Item->new(%$item);
            push @items, $obj;
        }
    }
    return \@items;
}

=head1 METHODS

=head2 amazon_order_number

=head2 email

The buyer email.

=head2 order_date

The date when the order processing was complete or when the order was
placed as a L<DateTime> object.

=head2 items

Return a list of L<Amazon::MWS::XML::Response::OrderReport::Item>,
which acts (more or less) like L<Amazon::MWS::XML::OrderlineItem>.

=cut

sub amazon_order_number {
    return shift->struct->{AmazonOrderID};
}

sub email {
    my $self = shift;
    if (my $billing = $self->struct->{BillingData}) {
        if (exists $billing->{BuyerEmailAddress}) {
            return $billing->{BuyerEmailAddress};
        }
    };
    return;
}


# OrderDate The date the order was placed
# OrderPostedDate The date the buyer's credit card was charged and order processing was completed

sub order_date {
    my $self = shift;
    my $struct = $self->struct;
    # maybe this would need a different method, but we don't know what
    # to do with it anyway.
    my $date = $struct->{OrderPostedDate} || $struct->{OrderDate};
    return DateTime::Format::ISO8601->parse_datetime($date);
}

sub items {
    return @{ shift->_items_ref };
}

1;
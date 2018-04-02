package Foo;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    return bless { %args }, $class;
}

sub sample_method {
    my ($self) = @_;
    print $self->{sample_data};
}

1;

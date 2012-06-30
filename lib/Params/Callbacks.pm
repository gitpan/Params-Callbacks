package Params::Callbacks;

# Copyright (c) 2012 Iain Campbell. All rights reserved.
#
# This work may be used and modified freely, but I ask that the copyright 
# notice remain attached to the file. You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note 
# listing the modifications you have made.

BEGIN {
    $Params::Callbacks::AUTHORITY = 'cpan:CPANIC';
    $Params::Callbacks::VERSION   = '1.00';
}

use strict;
use warnings;

require Exporter;

our @ISA         = qw/Exporter/;
our @EXPORT_OK   = qw/callbacks with list item/;
our %EXPORT_TAGS = (
    with => [ qw/with item list/ ],
    all  => [ @EXPORT_OK ]
);

sub extract {
    my @callbacks;
    unshift @callbacks, pop while ref $_[-1] eq 'CODE';
    bless( \@callbacks, shift ), @_;
}

sub filter {
    local $@;
    my @callbacks = @{ +shift };
    
    @_ = $_ unless @_;
    map { @_ = $_->(@_) } @callbacks;
    return @_;
}

sub callbacks { 
    __PACKAGE__->extract(@_); 
}

sub with (&;@) {
    my $topic = shift;
    my($callbacks, @args) = __PACKAGE__->extract(@_);
    $callbacks->filter( $topic->(@args) );
}

sub list (&;@) {
    return @_;
}

sub item (&;@) {
    my $code = shift;
    sub {
        map { $code->( local $_ = $_ ) } @_;
    }, @_;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Params::Callbacks - callback helper and topicalizer tools

=head1 SYNOPSIS

    # Using the object oriented calling style...

    use Params::Callbacks;

    sub counted {
        my ($callbacks, @args) = Params::Callbacks->extract(@_);
        $callbacks->filter(@args);
    }

    my $size = counted 1, 2, 3, sub {
        print "> $_\n" for @_;
        return @_;
    };

    print "$size items\n";

    # > 1
    # > 2
    # > 3
    # 3 items
    
    # Or, just mix-in the "callbacks" function...

    use Params::Callbacks qw/callbacks/;

    sub counted {
        my ($callbacks, @args) = &callbacks;
        $callbacks->filter(@args);
    }

    my $size = counted 'A', 'B', 'C', sub {
        print "> $_\n" for @_;
        return @_;
    };

    print "$size items\n";

    # > A
    # > B
    # > C
    # 3 items
    
    # Or, use my pre-cooked topicalizer. It's like "map" but with 
    # the topic up-front and in your face instead of further down 
    # in the source, somewhere...

    use Params::Callbacks qw/:with/;

    with { 'A', 'B', 'C' } 
        item { print "> $_\n" }             # Process each item
        list { print @_ . " items\n" };     # Process entire list

    # > A
    # > B
    # > C
    # 3 items

=head1 DESCRIPTION

Provides a very simple mechanism for converting an ordinary function into 
a function that will allow its result to be filtered through, and possibly
altered by, an optional callback queue before it is passed the caller. 

=head2 TRAINING FUNCTIONS TO HANDLE CALLBACKS

=over 5

=item B<( $callbacks, @params ) = Params::Callbacks-E<gt>extract( @_ );>

=item B<( $callbacks, @params ) = callbacks( @_ );>

=item B<( $callbacks, @params ) = &callbacks;>

Takes a list (here it is C<@_>) and creates a callback queue (C<$callbacks>)
from any B<trailing> code references and/or anonymous subs in that list. A 
new list is returned containing a reference to the callback queue followed 
by all those items in the original list that were not callbacks.

For purposes of illustration, I'm using Perl's built-in C<@_>, which is 
probably typical given the nature of the task at hand. Nevertheless, any 
list may be processed; though, prefixing the C<callbacks> function call 
with an ampersand "&" is probably only relevant when working with C<@_>.

A callback queue may be empty, i.e. contain no callbacks. That's ok.

=item B<OUTPUT = $callbacks-E<gt>filter( [INPUT] );>

Passes a "would be" result (C<INPUT>) into the head of the callback queue. 
The final stage of the queue yields the final result (C<OUTPUT>). Both, 
C<INPUT> and C<OUTPUT> may be lists of zero, one or more scalars. Passing 
no arguments to the C<filter> method causes C<$_> to be used. 

An empty callback queue yields the same result that was passed into it.

=back

=head2 USING THE C<with> TOPICALIZER AND THE C<item> / C<list> STAGES

=over 5

=item C<[RESULT = ]with BLOCK [STAGE [STAGE [STAGE [...]]]]> 

The C<with> function takes a BLOCK as its first argument, which may be
followed by zero or more stages. Each stage may be a per-item-oriented
C<item BLOCK> stage, or the list-oriented C<list BLOCK> and C<sub BLOCK>
stages.

Per-item-oriented stages process the result of the previous stage on 
item at a time, i.e. if the previous stage issued a list, each item 
in that list is processed separately. List-oriented stages process 
the entire result from the previous stage; if the previous stage is
an item-oriented stage then all the results are gathered together 
before being passed on. So, C<item> and C<list> stages can be mixed
freely.

The C<sub BLOCK> stage works just like the C<list BLOCK> stage, but
requires a comma to separate it from anything that follows. If that's
too much ugly, just use C<list BLOCK>.

Essentially, you end up with something looking like this:

    with { ... }
        item { ... }
        list { ... }
        # etc
    ;

It's a beautiful structure, allowing the developer to constrain 
logic and temporary state within an inner block and away from
the main flow, and process the results in a similar fashion.

Sure, we have C<map> and C<grep> but they're back-to-front and 
sometimes that just doesn't look right. 

=back

=head1 EXPORTS

=head2 @EXPORT

None.

=head2 @EXPORT_OK

callbacks, with, list, item.

=head2 %EXPORT_TAGS

=over 4

=item C<:all>

Everything in @EXPORT_OK.

=item C<:with>

with, list, item.

=back 

=head1 BUGS AND FEATURE REQUESTS

Too many features; not enough bugs? Just drop me a line and I'll see what
I can do to help.  

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Iain Campbell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

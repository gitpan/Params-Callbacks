package Params::Callbacks;

# Copyright (c) 2012 Iain Campbell. All rights reserved.
#
# This work may be used and modified freely, but I ask that the copyright 
# notice remain attached to the file. You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note 
# listing the modifications you have made.

BEGIN {
    $Params::Callbacks::AUTHORITY = 'cpan:CPANIC';
    $Params::Callbacks::VERSION   = '1.12';
    $Params::Callbacks::VERSION   = eval $Params::Callbacks::VERSION;
}

use 5.008_004;
use strict;
use warnings;

require Exporter;

our @ISA = qw/Exporter/;

our @EXPORT_OK = qw/callbacks list item extract_callbacks/;

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ]
);

# Constructor to create callback queue object.

sub extract {
    my @callbacks;
    unshift @callbacks, pop while ref $_[-1] eq 'CODE';
    bless( \@callbacks, shift ), @_;
}

# Yield result and control to callback queue.

sub yield {
    my $callbacks = shift;
    map { @_ = $_->(@_) } @{$callbacks};
    return @_;
}

# Deprecated "filter" shortly after initial release.
# Use "yield" instead.

*filter = \&yield;

# Non-OO function to create creat callback queue object.
# Exported on request.

sub callbacks { 
    __PACKAGE__->extract(@_); 
}

# Deprecated "extract_callbacks" shortly after initial release.
# Use "callbacks" instead.

*extract_callbacks = \&callbacks;

# Syntactic sugar: like "sub { ... }" without the need for a comma to separate
# more than one. 
#
# Exported on request.

sub list (&;@) {
    return @_;
}

# Syntactic sugar: like "list { ... }" but process result set one item at a
# time.
#
# Exported on request.

sub item (&;@) {
    my $code = shift;
    sub { map { $code->( local $_ = $_ ) } @_ }, @_;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Params::Callbacks - Enable functions to accept blocking callbacks

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
    
=head1 DESCRIPTION

This package provides the developer with an easy and consistent method for 
converting a function that returns a result, into a function that will allow
its result to pass through one or more blocking callbacks, before it is 
delivered to the caller. 

It is up to the function's author to decide how and where in the function's
flow those callbacks should be invoked. This is could be important during the
creation of sets of results: one could apply the callbacks to a finished set, 
or apply them to each element of the result set as it is added. 

=head2 TRAINING FUNCTIONS TO HANDLE CALLBACKS

=over 5

=item B<( $callbacks, LIST ) = Params::Callbacks-E<gt>extract( LIST );>

=item B<( $callbacks, LIST ) = callbacks LIST;>

Accepts a list of values and strips off any B<trailing> code-references, 
which are used to create a callback queue. A new list is returned consisting
of a reference to the callback queue, followed by the originally listed 
items that were not callbacks. Note that only trailing code-references are
considered callbacks; once an inelligible items is encountered the collection
stops.

A callback queue may be empty and that's fine.

=item B<( $callbacks, @params ) = &callbacks;>

A special form of call to C<callbacks>, using the current C<@_>.

=item B<RESULT = $callbacks-E<gt>yield( RESULT );>

Yields a result up to the callback queue, returning whatever comes out at
the other end.

A result will pass through an empty callback queue unmodified.

=item B<list BLOCK [CALLBACK-LIST]>

=item B<sub STATEMENT-BLOCK[, CALLBACK-LIST]>

On their own, callbacks receive their input result as a list; C<@_>, to
be precise, since they're really only functions. 

When invoking a function that accepts callbacks, you might string a sequence
of code-references, or anonymous C<sub> blocks together, being careful to
separate each witha comma (,), e.g:

    function ARGUMENTS, sub {
        ...
    }, sub {
        ...
    }, sub {
        ...
    };

Alternatively, use the C<list> function to do exactly the same but dispense 
line-noise altogether:

    function ARGUMENTS, list {
        ...
    } list {
        ...
    } list {
        ...
    }

Yes, much easier on the eye!
    
=item B<item STATEMENT-BLOCK [CALLBACK-LIST]>

Use in place of C<list> when you want the input result one item at a time, 
i.e. even though the result is a list, the callback is called once for each
item in the list and all items are gathered before being passed on.

Both the C<item> and C<list> callbacks may be mixed freely.

=back

=head1 EXPORTS

=head2 @EXPORT

None.

=head2 @EXPORT_OK

=over 5 

=item callbacks, list, item, (DEPRECATED: extract_callbacks)

=back 

=head2 %EXPORT_TAGS

=over 5

=item C<:all>

Everything in @EXPORT_OK.

=back 

=head1 BUGS AND FEATURE REQUESTS

Too many features; not enough bugs? Just drop me a line and I'll see what
I can do to help.  

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENCE

Params::Callbacks, Version 1.01

Copyright (C) 2012 by Iain Campbell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

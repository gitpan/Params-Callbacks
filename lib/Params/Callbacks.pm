package Params::Callbacks;

# Copyright (c) 2012 Iain Campbell. All rights reserved.
#
# This work may be used and modified freely, but I ask that the copyright 
# notice remain attached to the file. You may modify this module as you 
# wish, but if you redistribute a modified version, please attach a note 
# listing the modifications you have made.

use 5.008_004;
use strict;
use warnings;

require Exporter;

BEGIN {
    $Params::Callbacks::AUTHORITY = 'cpan:CPANIC';
    $Params::Callbacks::VERSION   = '2.00';
    $Params::Callbacks::VERSION   = eval $Params::Callbacks::VERSION;
}

our @ISA = qw/Exporter/;

our %EXPORT_TAGS = (
    'all' => [ qw/callbacks block bleach yield/ ]
);

our @EXPORT_OK = @{$EXPORT_TAGS{'all'}};

##
# Create a list of callbacks from the trailing coderefs in the parameter 
# list, returning a list comprising the Params::Callbacks object and any
# parameters that didn't qualify as callbacks.
#
# Example
#
#   sub your_function
#   {
#       my ($callbacks, @params) = Params::Callbacks->extract(@_);
#           .
#           .
#           .
#   }
#
sub extract 
{
    my @callbacks;

    unshift @callbacks, pop
        while ref $_[-1] eq 'CODE'
    ;

    my $callback_queue = bless \@callbacks, shift;
    
    return $callback_queue, @_;
}

##
# More terse, but also more readable, alternative to the 
# Params::Callback->extract(@_) calling idiom:
#
# Example
#
#   sub your_function
#   {
#       my ($callbacks, @params) = &callbacks;
#           .
#           .
#           .
#   }
#
sub callbacks 
{ 
    @_ = (__PACKAGE__, @_);
    
    goto &extract;
} 

##
# Yield the result to the caller via any queued callbacks. Works just like
# the "return" statement, except that your result is being filtered:
#
# Example
#
#   sub your_function
#   {
#       my ($callbacks, @params) = &callbacks;
#           .
#           .
#           .
#       $callbacks->yield(@params);
#   }
#
sub yield 
{
    my ($callback_queue, @list) = @_;

    return @list && defined($callback_queue) && @{$callback_queue}
        ? map { @list = $_->(@list) } @{$callback_queue}
        : @list
    ;
}

##
# Appends a blocking callback to the call just as "sub {...}" would, without
# the need for a comma (,) separating each callback. 
#
# Example
#
#   your_function 1, 2, 3, block {
#       @_;
#   } block {
#       @_;
#   } block {
#       @_;
#   };
#
# Or the scruffier alternative
#
#   your_function 1, 2, 3, sub {
#       @_;
#   }, sub {
#       @_;
#   }, sub {
#       @_;
#   };
#
sub block (&;@) 
{ 
    return @_; 
}

##
# Like "block" the "bleach" subroutine appends a blocking callback to the 
# call just as "sub {...}" would, without the need for a comma (,) separating 
# each callback.
#
# Unlike "block", which processes the result list in its entirety, "bleach" 
# processes each item in the result list seperately. You can mix "bleach" and
# "block" stages freely, using them to split and gather results.
#
# Example
#
#   your_function 1, 2, 3, bleach {
#       @_;
#   } bleach {
#       @_;
#   } block {
#       @_;
#   };
#
sub bleach (&;@) 
{
    my $code = shift;

    die 'Expected code reference or anonymous subroutine'
        unless ref $code && ref $code eq 'CODE'
    ;

    return sub { map { $code->($_) } @_ }, @_;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Params::Callbacks - Enable functions to accept blocking callbacks

=head1 SYNOPSIS

    # A simple filter, which does nothing on its own:

    sub filter
    {
        my ($callbacks, @params) = &callbacks;
        $callbacks->yield(@params);
    }

    # Invoke the filter, allowing only odd numbered items to 
    # pass through then render the result before returning
    # the filtered list:

    filter 1, 2, 3, 4, 5, bleach {
        $_[0] % 2 != 0 ? @_ : ();
    } block {
        print join(', ', @_), "\n";
        return @_;
    };
    
=head1 DESCRIPTION

This package provides a simple method for converting a standard function 
into a function that can filter its result through one or more callbacks
provided by the caller.

=head1 CONFIGURING A FUNCTION TO ACCEPT CALLBACKS

Your function must do two things in order to be able to filter its results
through a list of callbacks. It must first separate callbacks from the data
passed to the function when it was invoked. After completion, the function's
result must be passed to the callbacks for further processing before being
delivered to the caller.

These two tasks are completed using the C<callbacks> function and the 
C<yield> method, like so:

    sub minimalist_function
    {
        # Create a callback queue and list of function parameters
        # from @_:
        #
        my ($callbacks, @params) = &callbacks;

        ...

        # Yield a result via the callback queue:
        #
        $callbacks->yield(@params);
    }

=over 5

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

=item B<RESULT = $callbacks-E<gt>yield(RESULT);>

Yields a result via the callback queue, returning whatever comes out at
the other end.

A result will pass through an empty callback queue unmodified.

=item B<block BLOCK [CALLBACK-LIST]>

Introduces a blocking callback that processes the entire result set as a 
list.

If the terminating expression is an empty list, an empty list is passed
along the callback queue to the caller unless something more meaningful
is added.

=item B<bleach STATEMENT-BLOCK [CALLBACK-LIST]>

Introduces a blocking callback that processes the entire result set an
item at a time.

If the terminating express is an empty list, the item is removed from
the result. Conversely, lists may be returned resulting in additional
elements appearing in the result.

=back

=head1 BUG REPORTS

Please report any bugs to L<http://rt.cpan.org/>

=head1 AUTHOR

Iain Campbell <cpanic@cpan.org>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2012 by Iain Campbell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

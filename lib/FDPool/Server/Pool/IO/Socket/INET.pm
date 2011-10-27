package FDPool::Server::Pool::IO::Socket::INET;

use strict;
use warnings;
use parent qw(FDPool::Server::Pool);

use IO::Socket::INET;
use Socket;

our $VERSION = '0.01';

sub create_pool_sock {
    my ( $class, $server, $pool_args ) = @_;

    my $sock = IO::Socket::INET->new(
        %$pool_args,
    ) or croak($!);

    return ( $sock, $sock );
}

1;
__END__

=head1 NAME

FDPool::Server::Pool::IO::Socket::INET -

=head1 SYNOPSIS

  use FDPool::Server::Pool::IO::Socket::INET;

=head1 DESCRIPTION

FDPool::Server::Pool::IO::Socket::INET is

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# Local Variables:
# mode: perl
# perl-indent-level: 4
# indent-tabs-mode: nil
# coding: utf-8-unix
# End:
#
# vim: expandtab shiftwidth=4:


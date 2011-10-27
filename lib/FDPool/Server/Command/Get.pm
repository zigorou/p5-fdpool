package FDPool::Server::Command::Get;

use strict;
use warnings;

use Carp;
use IO::Socket::UNIX;
use List::Util qw(first);
use POSIX qw(dup2);
use Socket;
use Socket::PassAccessRights;

our $VERSION = '0.01';

sub handle_request {
    my ( $class, $server, $params ) = @_;
    my ($name, $path) = @$params{qw/name path/};

    unless ( $server->exists_pool_by_name($name) ) {
        return (0, {
            error => sprintf('The pool is not exists (name: %s)', $name),
        });
    }

    unless ( defined $path && -S $path ) {
        return (0, {
            error => sprintf('The path is not unix domain socket (path: %s)', $path || ''),
        });
    }

    my $pool = $server->get_pool_by_name($name);
    my $pool_fd = first { not $pool->{$_} } keys %$pool;

    unless (defined $pool_fd) {
    }

    my $clone_fd;

    my $send_sock = IO::Socket::UNIX->new(
        Peer => $path,
        Type => SOCK_STREAM,
    ) or croak($!);
}

1;
__END__

=head1 NAME

FDPool::Server::Command::Get -

=head1 SYNOPSIS

  use FDPool::Server::Command::Get;

=head1 DESCRIPTION

FDPool::Server::Command::Get is

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
 FDPool::Server::Command::Get;

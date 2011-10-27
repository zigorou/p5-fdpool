package FDPool::Server::Loop::Select;

use strict;
use warnings;
use parent qw(FDPool::Server::Loop);

use IO::Select;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : { @_ };

    %$args = (
        timeout => 10,
        clients => [],
        keepalive => 1,
        %$args,
    );

    $args->{loop} ||= IO::Select->new;

    my $self = bless $args => $class;
    $self;
}

sub accept_loop {
    my ( $self, $server ) = @_;

    my $s = $self->{loop};
    $s->add( $server->create_server_sock );

    my $term_received = 0;

    $SIG{TERM} = sub {
        $term_received++;
    };

    while (!$term_received) {
        if ( my @ready = $s->can_read( $self->{timeout} ) ) {
            for my $sock ( @ready ) {
                if ( $sock == $server->{host_sock} ) {
                    my $client_sock = $sock->accept( $self->{timeout} );
                    $client_sock->blocking(0) or croak($!);
                    $self->{clients}[fileno($client_sock)] = time;
                    $s->add( $client_sock );
                }
                elsif ( $self->{clients}[fileno($sock)] ) {
                    $server->handle_command_request( $sock );
                }
                else {
                    ### $server->handle_pool_sock_read( $sock );
                }
            }
        }

        if ( my @ready = $s->can_write( $self->{timeout} ) ) {
            for my $sock ( @ready ) {
                if ( $sock == $server->{host_sock} ) {
                    next;
                }
                elsif ( $self->{clients}[fileno($sock)] ) {
                    $server->handle_command_response( $sock );
                    $self->{clients}[fileno($sock)] = undef;
                    unless ($self->{keepalive}) {
                        $sock->close or croak($!);
                    }
                }
                else {
                    ### $server->handle_pool_sock_write( $sock );
                }
            }
        }
    }

    return 1;
}

sub add_sock {
    my ( $self, $sock ) = @_;
    $self->{loop}->add($sock) or croak($!);
}

sub delete_sock {
    my ( $self, $sock ) = @_;
    $self->{loop}->delete($sock) or croak($!);
}

1;
__END__

=head1 NAME

FDPool::Server::Loop::Select -

=head1 SYNOPSIS

  use FDPool::Server::Loop::Select;

=head1 DESCRIPTION

FDPool::Server::Loop::Select is

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


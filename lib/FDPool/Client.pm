package FDPool::Client;

use strict;
use warnings;

use Croak;
use File::Temp qw(tempfile);
use IO::Socket::UNIX;
use JSON::XS;
use Socket;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : { @_ };

    %$args = (
        peer_path => undef,
        peer_sock => undef,
        %$args,
    );

    unless ( defined $args->{peer_path} ) {
        croak 'peer_path parameter is mandatory';
    }

    unless ( -S $args->{peer_path} ) {
        croak sprintf('given peer_path is not socket (%s)', $args->{peer_path});
    }

    my $self = bless $args => $class;

    return $self;
}

sub get_fd {
    my ( $self, $fd_name ) = @_;

    my $recv_sock = $self->create_receive_sock;
    my $params = {
        name => $fd_name,
        path => $recv_sock->hostpath,
    };

    my ($rv, $result) = $self->send_command( GET => $params );

    if ($rv) {
        return $result->{fd};
    }
    else {
        return undef;
    }
}

sub restore_fd {
    my ( $self, $fd ) = @_;

    my $params = {
        fd => $fd,
    };

    my ($rv, $result) = $self->send_command( RESTORE => $params );

    if ($rv) {
        return 1;
    }
    else {
        return undef;
    }
}

sub stats {
}

sub send_command {
    my ($self, $cmd, $params) = @_;

    $params ||= {};

    my $serialized_params = encode_json($params);
    my $client_sock       = $self->create_client_sock;

    my $request_data = $cmd . " " . length($serialized_params) . "\r\n" 
        . $serialized_params;

    unless ( $client_sock->send( $request_data ) ) {
        return (0, { error => $! });
    }

    chomp(my $response_header = <$client_sock>);
    my ( $response_code, $response_body_size ) = split(' ', $response_header);

    unless ( $client_sock->recv(my $response_body, $response_body_size) ) {
        return (0, { error => sprintf('Connection closed by peer (peerhost: %s)', $client_sock->peerhost) });
    }

    my $response_data = decode_json( $response_body );

    return $response_code eq 'OK' ? 
        (1, $response_data) : (0, $response_data);
}

sub create_client_sock {
    my $self = shift;

    unless ( defined $self->{peer_sock} && $self->{peer_sock}->connected ) {
        $self->{peer_sock} = IO::Socket::UNIX->new(
            Peer => $self->{peer_path},
            Type => SOCK_STREAM,
        ) or croak $!;
    }

    return $self->{peer_sock};
}

sub create_receive_sock {
    my $self = shift;

    my $file_name;
    (undef, $file_name) = tempfile(
        sprintf('recv_sock_%d_XXXXXX', $$),
        UNLINK => 0,
        TMPDIR => 1,
        SUFFIX => '.sock',
    ) or croak($!);

    my $recv_sock = IO::Socket::UNIX->new(
        Listen => 1,
        Local  => $file_name,
        Type   => SOCK_STREAM,
    ) or croak($!);

    return $recv_sock;
}

1;

__END__

=head1 NAME

FDPool -

=head1 SYNOPSIS

  use FDPool::Client;

=head1 DESCRIPTION

FDPool::Client is

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

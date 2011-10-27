package FDPool::Server;

use strict;
use warnings;

use Carp;
use Class::Load qw(load_class is_class_loaded);
use IO::Poll;
use IO::Socket::UNIX;
use JSON::XS;
use POSIX qw(dup2);
use Socket;
use Socket::PassAccessRights;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $args = ref $_[0] ? $_[0] : { @_ };

    %$args = (
        host_path   => undef,
        host_sock   => undef,
        timeout     => 10,
        fds         => [],
        fd_names    => {},
        loop        => [ 'Select' => {} ],
        pools       => [qw/IO::Socket::INET/],
        pool_map    => {},
        commands    => [qw/Get Restore/],
        command_map => {},
        config      => {},
        %$args,
    );

    unless ( defined $args->{host_path} ) {
        croak 'host_path parameter is mandatory';
    }

    my $self = bless $args => $class;
    $self;
}

sub init_pool_by_name {
    my ($self, $name) = @_;
    $self->{fd_name}{$name} = {};
}

sub exists_pool_by_name {
    my ($self, $name) = @_;
    exists $self->{fd_name}{$name} ? 1 : 0;
}

sub get_pool_by_name {
    my ($self, $name) = @_;
    $self->{fd_name}{$name};
}

sub add_connection {
    my ($self, $name, $fd, $client_obj) = @_;

    $self->{fd_name}{$name}{$fd} = 0;
    $self->{fds}[$fd]            = $client_obj;
}

sub delete_connection {
    my ($self, $name, $fd) = @_;

    delete $self->{fd_name}{$name}{$fd};
    $self->{fds}[$fd] = undef;
}

sub set_connection_status {
    my ($self, $name, $fd, $is_used) = @_;

    $self->{fd_name}{$name}{$fd} = $is_used;
}

sub get_client_object {
    my ($self, $fd) = @_;
    $self->{fds}[$fd];
}

sub setup_server {
    my $self = shift;
    $self->create_server_sock;
}

sub setup_loop {
    my $self = shift;

    unless ( defined $self->{loop} && UNIVERSAL::isa($self->{loop}, 'FDPool::Server::Loop') ) {
        my ($loop, $loop_args) = @{$self->{loop}};

        $self->{loop} = $self->load_extension(
            $loop, $loop_args, { default_prefix => 'FDPool::Server::Loop::' },
        );
    }

    1;
}

sub setup_pools {
    my $self = shift;

    for my $type (@{$self->{pools}}) {
        $self->{pool_map}{$type} = $self->load_extension(
            $type,
            undef,
            {
                default_prefix  => 'FDPool::Server::Pool::',
                create_instance => 0,
            },
        );
    }

    ### pool_name => pool_node_config
    my $config = $self->{config}{pool} || {};

    for my $pool_name (keys %$config) {
        $self->init_pool_by_name($pool_name);

        my $pool_opts = $config->{$pool_name};
        my ( $type, $connections, $args) = @$pool_opts{qw/type connections args/};

        unless (exists $self->{pool_map}{$type}) {
            croak sprintf(q|%s pool type is not enabled|, $type);
        }

        my $pool_obj = $self->{pool_map}{$type};

        for ( 1 .. $connections ) {
            my ($sock, $client_obj) = $pool_obj->create_pool_sock( $self, $args );
            $self->add_connection( $pool_name, fileno($sock), $client_obj );
        }
    }

    1;
}

sub setup_commands {
}

sub run {
    my $self = shift;
    $self->{loop}->accept_loop( $self );
    exit 0;
}

sub handle_command_request {
    my ($self, $conn_sock) = @_;

    
}

sub handle_command_response {
    my ($self, $conn_sock) = @_;
}

sub shutdown_server {
    my $self = shift;

    if (defined $self->{host_sock} && $self->{host_sock}->connected) {
        close($self->{host_sock}) or croak($!);
    }

    if (defined $self->{host_path} && -S $self->{host_path}) {
        unlink($self->{host_path}) or croak($!);
    }

    1;
}

sub DESTROY {
    my $self = shift;
    $self->shutdown_server;
}

sub create_server_sock {
    my $self = shift;

    unless ( defined $self->{host_sock} && $self->{host_sock}->connected ) {
        $self->{host_sock} = IO::Socket::UNIX->new(
            Blocking  => 0,
            Listen    => SOMAXCONN,
            Local     => $self->{host_path},
            Timeout   => $self->{timeout},
            Type      => SOCK_STREAM,
            ReuseAddr => SO_REUSEADDR,
        ) or croak($!);
    }

    $self->{host_sock};
}

sub load_extension {
    my ($self, $ext, $ext_args, $opts) = @_;

    $opts ||= {};
    %$opts = (
        default_prefix => 'FDPool::Server::Pool::',
        create_instance => 1,
        %$opts,
    );

    if (index($ext, '+') == 0) {
        $ext = substr($ext, 1);
    }
    else {
        $ext = $opts->{default_prefix} . $ext;
    }

    unless (is_class_loaded $ext) {
        load_class $ext or croak(sprintf(q|Can't load module (%s)|, $ext));
    }

    if ( $opts->{create_instance} ) {
        $ext_args ||= {};
        return $ext->new($ext_args);
    }
    else {
        return $ext;
    }
}


1;
__END__

=head1 NAME

FDPool::Server -

=head1 SYNOPSIS

  use FDPool::Server;

=head1 DESCRIPTION

FDPool::Server is

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


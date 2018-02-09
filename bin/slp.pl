#!/usr/bin/env perl
#!/home/utils/perl-5.22/5.22.0-016/bin/perl
# PODNAME: slp.pl

use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib '/home/eash/.perlbrew/libs/5.24-latest@plsense/lib/perl5';

package slp;
use Moo;
use Language::Server;
use Try::Tiny;
use Log::Any '$log';
use Log::Any::Adapter('File', '/tmp/perl-lsp.log');
use Data::Printer;
use Cpanel::JSON::XS;
use EV;
use JSON::RPC2::Server;
use Encode();
$|++;
use AnyEvent::Handle;
use AE;

#VERSION

has server => (
    is      => 'lazy',
    default => sub {
        JSON::RPC2::Server->new();
    },
);

has lsp => ( 
   is => 'lazy',
   default=> sub { Language::Server->new},
);
sub register_methods {
    my $self = shift;
    $self->server->register_named('initialize', sub {$self->lsp->initialize(@_)});
    $self->server->register_named('initialized', sub {return});

##### register commands #####
    $self->server->register_named('workspace/didChangeConfiguration', sub {$self->lsp->didChangeConfiguration(@_)});
    $self->server->register_named('textDocument/didOpen',             sub {$self->lsp->didOpen(@_)});
    $self->server->register_named('textDocument/didChange',           sub {$self->lsp->didChange(@_)});
    $self->server->register_named('textDocument/rename',              sub {$self->lsp->rename(@_)});
    $self->server->register_named('textDocument/completion',          sub {return});
    $self->server->register_named('textDocument/didSave',             sub {return});
    $self->server->register_named('textDocument/formatting',          sub {$self->lsp->formatting(@_)});
    $self->server->register_named('textDocument/rangeFormatting',     sub {$self->lsp->range_formatting(@_)});
    $self->server->register_named('exit',                             sub {exit});
}

sub run {
    my $self=shift;
    #############################################
    #
    $self->register_methods;
    $log->debug('Started');

    my $c_length = 0;

    my $io = IO::Handle->new();

    my $io_handle = AnyEvent::Handle->new(
        fh       => \*STDIN,
        on_error => sub {
            $log->errorf('on_error: %s', $_[2]);
            exit;
        },
        on_eof => sub {
            $log->debug('Client disconnected');
            exit;
        }
    );

    $io_handle->on_read(
        sub {
            my ($handle) = @_;

            #get header info
            $handle->push_read(
                line => "\r\n\r\n",
                sub {
                    my ($handle, $header) = @_;
                    $log->trace('header:' . $header);
                    if ($header =~ s/Content-Length: (\d+)\s*$//) {
                        $c_length = $1;
                        $log->trace("length is $c_length");
                        $handle->push_read(
                            chunk => $c_length,
                            sub {$self->process($_[1])},
                        );
                    }
                }
            );
        },
    );

    # cause loop
    EV::run;

}

sub process {
    my $self=shift;
    my ($line) = @_;
    try {
        my $data = decode_json($line);

        $log->tracef("method called %s, id %s", $data->{method}, $data->{id} // 'null');
        $log->tracef("json in: %s", $data);
    }
    catch {
        $log->tracef('not json %s', $line);
        return;
    };
    $self->server->execute(
        $line,
        sub {
            my ($response) = @_;
            my $length = length(Encode::encode('UTF-8', $response));
            return if $length == 0;
            my $msg = sprintf("Content-Length: %i\r\n\r\n%s\r\n", $length + 2, $response);
            print $msg;

            $log->trace("output:$msg");
        }
    );
}
__PACKAGE__->new->run if !caller;
1;

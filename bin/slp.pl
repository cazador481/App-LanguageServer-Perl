#!/home/utils/perl-5.22/5.22.0-016/bin/perl
use strict;
use warnings;
use lib 'lib';
use lib '/home/eash/.perlbrew/libs/5.24-latest@plsense/lib/perl5';
use Language::Server;
use Try::Tiny;
use Log::Any '$log';
use Log::Any::Adapter('File', '/tmp/perl-lsp.log');
use Data::Printer;
use JSON;
use JSON::RPC2::Server;
use Encode();
$|++;
use AnyEvent::Handle;
use AE;

my $lsp = Language::Server->new;
my $server = JSON::RPC2::Server->new();
$server->register_named('initialize',              sub {$lsp->initialize(@_)});

##### register commands #####
$server->register_named('workspace/didChangeConfiguration', sub {$lsp->didChangeConfiguration(@_)});
$server->register_named('textDocument/didOpen',    sub {$lsp->didOpen(@_)});
$server->register_named('textDocument/didChange',  sub {$lsp->didChange(@_)});
$server->register_named('textDocument/rename',     sub {$lsp->rename(@_)});
$server->register_named('textDocument/completion', sub {return});
$server->register_named('textDocument/didSave',    sub {return});
$server->register_named('textDocument/formatting',    sub {$lsp->formatting(@_)});
$server->register_named('textDocument/rangeFormatting',    sub {$lsp->range_formatting(@_)});
$server->register_named('exit',    sub {exit});

#############################################
#
$log->debug('Started');

my $c_length = 0;

my $io = IO::Handle->new();

my $io_handle=AnyEvent::Handle->new(
    fh => \*STDIN,
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
                if ($header =~ s/Content-Length: (\d+)\s*$//)
                {
                    $c_length = $1;
                    $log->trace("length is $c_length");
                    $handle->push_read(
                        chunk => $c_length,
                        sub {process($server, $_[1])},
                    );
                }
            }
        );
    },
);
# cause loop
use EV;
EV::run;#cv->recv;
exit;

sub process
{
    my ($server, $line) = @_;
    try
    {
        my $data = from_json($line);

        $log->tracef("method called %s, id %s", $data->{method}, $data->{id} // 'null');
    }
    catch
    {
        $log->tracef('not json %s', $line);
        return;
    };
    $server->execute(
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

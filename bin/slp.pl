#!/home/utils/perl-5.22/5.22.0-016/bin/perl
use strict;
use warnings;
use lib 'lib';
use lib '/home/eash/.perlbrew/libs/5.24-latest@plsense/lib/perl5';
use Language::Server;
use Try::Tiny;
$|++;
my $lsp = Language::Server->new;
use Log::Any '$log';
use Log::Any::Adapter('File', '/home/eash/log');
use Data::Printer;
use JSON;
use JSON::RPC2::Server;
use Encode();
my $server = JSON::RPC2::Server->new();
$server->register_named('initialize',              sub {$lsp->initialize(@_)});
$server->register_named('workspacce/didChangeConfiguration', sub {$lsp->didChangeConfiguration(@_)});
$server->register_named('textDocument/didOpen',    sub {$lsp->didOpen(@_)});
$server->register_named('textDocument/didChange',  sub {$lsp->didChange(@_)});
$server->register_named('textDocument/rename',     sub {$lsp->rename(@_)});
$server->register_named('textDocument/completion', sub {return});
$server->register_named('textDocument/didSave',    sub {return});
$server->register_named('textDocument/formatting',    sub {$lsp->formatting(@_)});
$server->register_named('textDocument/rangeFormatting',    sub {$lsp->range_formatting(@_)});
$log->debug('Started');

my $c_length = 0;

my $io = IO::Handle->new();
$io->fdopen(fileno(STDIN), "r");
while (my $line = $io->getline)
{
    $line =~ s/\R+//;

    # $log->infof("line:[%s]", $line);
    # $log->info('ea');
    if ($line =~ s/Content-Length: (\d+)\s*$//)
    {

        $c_length = $1;
        $io->getline;

        # $log->infof('1:%s', $io->getline);
        $io->read($line, $c_length);
        chomp $line;
        # $log->info("rpc:$line");
        process($server, $line);
    }
}

$log->debug('Finished');

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
    };
    $server->execute(
        $line,
        sub {
            my ($response) = @_;
            my $length = length(Encode::encode('UTF-8', $response));
            return if $length == 0 ;
            my $msg = sprintf("Content-Length: %i\r\n\r\n%s\r\n", $length+2, $response);
            print $msg;

            $log->trace("output:$msg");
        }
    );
}

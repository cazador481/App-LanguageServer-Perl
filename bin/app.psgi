use strict;
use warnings;
use lib '/home/eash/scripts/Language-Server/lib';
use JSON::RPC::Dispatch;
use Router::Simple;
use Language::Server;
my $lsp=Language::Server->new;

my $router = Router::Simple->new;


$router->connect(
    initialize = >{
        handler => $lsp,
        action =>'initialize',
    }
);

$router->connect(
    open => {
        handler => $lsp,
        action  => 'open'
    }
);
$router->connect(
    'textDocument/didOpen' => {
        handler => $lsp,
        action  => 'didOpen'
    }
);
my $dispatch = JSON::RPC::Dispatch->new(
    prefix => "Language::Server",
    router => $router,
);

# sub psgi_app
sub 
{
    my $env = shift;
    $dispatch->handle_psgi($env);
};

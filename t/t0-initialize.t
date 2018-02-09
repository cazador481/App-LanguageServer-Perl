use strict;
use warnings;
use Test2::Bundle::Extended;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use lib "$FindBin::RealBin/../bin";
require "$FindBin::RealBin/../bin/slp.pl";

use Language::Server::Plsense;
my $server=slp->new;
$server->register_methods;

my $lsp=$server->lsp;
my $init = init_func();
my $ret;
try_ok{$ret=$lsp->initialize(%$init)};
isnt($lsp->rootpath,undef,'rootpath set');
my $text='this is text';
my $uri='file:///tmp/test.pm';

try_ok {
    $ret = $lsp->didOpen(
        textDocument => {
            uri          => $uri,
            text => $text,
        },
      ),
      'open file'
};

is($lsp->plsense,1,'verify plsense variable set');
try_ok {
    $ret = $lsp->didChange(
        textDocument   => {uri   => $uri},
        contentChanges => [{text => $text, range => {},},],
    );
};
Language::Server::Plsense->stop;
note ("End of test");
## test _get_document
done_testing;
note ("End of test");

sub init_func {
    return {
        processId          => undef,
        rootUri            => "file://$FindBin::RealBin/t/",
        initializedOptions => {plsense=>0},
        capabilities       => {
            workspace => {
                applyEdit              => \1,
                workspaceEdit          => {documentChanges => \1,},
                didChangeConfiguration => {dynamicRegistration => \0,},
                didChangeWatchedFiles  => {dynamicRegistration => \1,},
                symbol                 => {dynamicRegistration => \0,},
                executeCommand         => {dynamicRegistration => \1,}
            },
            textDocument => {
                synchronization => {
                    dynamicRegistration => \1,
                    willSave            => \0,
                    willSaveWaitUntil   => \0,
                    didSaeve            => \0,
                },
                completion => {
                    dynamicRegistration => \0,
                    completionItem      => {
                        snippetSupport          => \0,
                        commitCharactersSupport => \0,
                        documentFormat          => {},  # MarkupKind
                    },

                    # completionItemKind => {
                    #
                    # },
                    contextSupport => \0,
                },
                hover => {
                    dynamicRegistration => \0,
                    contentFormat       => {},  # MarkupKind
                },
                signatureHelp => {
                    dynamicRegistration  => \0,
                    signatureInformation => {
                        documentationFormat => {},  # MarkupKind
                    },
                },
                references        => {dynamicRegistration => \0,},
                documentHighlight => {
                    #
                    # Whether document highlight supports dynamic registration.
                    #
                    dynamicRegistration => \0,
                },

                #
                # Capabilities specific to the `textDocument/documentSymbol`
                #
                documentSymbol => {
                    #
                    # Whether document symbol supports dynamic registration.
                    #
                    dynamicRegistration => \0,

                    #
                    # Specific capabilities for the `SymbolKind`.
                    #
                    symbolKind => {
                        #
                        # The symbol kind values the client supports. When this
                        # property exists the client also guarantees that it will
                        # handle values outside its set gracefully and falls back
                        # to a default value when unknown.
                        #
                        # If this property is not present the client only supports
                        # the symbol kinds from `File` to `Array` as defined in
                        # the initial version of the protocol.
                        #
                        valueSet => {},  #SymbolKind[];
                    }
                },

                #
                # Capabilities specific to the `textDocument/formatting`
                #
                formatting => {
                    #
                    # Whether formatting supports dynamic registration.
                    #
                    dynamicRegistration => \1,
                },

                #
                # Capabilities specific to the `textDocument/rangeFormatting`
                #
                rangeFormatting => {
                    #
                    # Whether range formatting supports dynamic registration.
                    #
                    dynamicRegistration => \1,
                },

                #
                # Capabilities specific to the `textDocument/onTypeFormatting`
                #
                onTypeFormatting => {
                    #
                    # Whether on type formatting supports dynamic registration.
                    #
                    dynamicRegistration => \0,
                },

                #
                # Capabilities specific to the `textDocument/definition`
                #
                definition => {
                    #
                    # Whether definition supports dynamic registration.
                    #
                    dynamicRegistration => \0,
                },

                #
                # Capabilities specific to the `textDocument/codeAction`
                #
                codeAction => {
                    #
                    # Whether code action supports dynamic registration.
                    #
                    dynamicRegistration => \0,
                },

                #
                # Capabilities specific to the `textDocument/codeLens`
                #
                codeLens => {
                    #
                    # Whether code lens supports dynamic registration.
                    #
                    dynamicRegistration => \0,
                },

                #
                # Capabilities specific to the `textDocument/documentLink`
                #
                documentLink => {
                    #
                    # Whether document link supports dynamic registration.
                    #
                    dynamicRegistration => \0,
                },

                #
                # Capabilities specific to the `textDocument/rename`
                #
                rename => {
                    #
                    # Whether rename supports dynamic registration.
                    #
                    dynamicRegistration => 1,
                },
            },
        },
        trace => 'off',
    };
}

sub send_rpc {
      my ($data) = @_;
      my $length = length(Encode::encode('UTF-8', $data));
      return if $length == 0;
      my $msg = sprintf("Content-Length: %i\r\n\r\n%s\r\n", $length + 2, $data);
      print $msg;

}

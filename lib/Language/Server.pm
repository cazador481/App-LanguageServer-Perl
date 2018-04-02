#ABSTRACT: Language::Server
package Language::Server;
use Moo;
use Types::Standard -types;
use Type::Utils qw(class_type);
use MooX::StrictConstructor;
use Data::Printer;
use Type::Params qw(compile);  #adds compile command for subroutine validation
use IPC::Run3;
use PPIx::EditorTools::RenameVariable;
use Perl::Tidy;
use Language::Server::Document;
use Language::Server::Editor qw();
use JSON;

use feature qw(state);

# use constant SELF=>class_type {class=>__PACKAGE__}; # Type::Type class self
use constant LSPErrorCode_InvalidParams => -32602;

with 'MooX::Log::Any';         # enable logger

# use namespace::autoclean;
#
#

#VERSION

has plsense => ( 
   is => 'rw',
   isa => Bool,
   default=>1,
   documentation=>'enable plense',
);
has documents => (
    is            => 'ro',
    isa           => HashRef,
    default       => sub {{}},
    documentation => 'files to process',
);

has value => (
    is      => 'rw',
    default => 0,
);

has rootpath => (is => 'rw',);

sub didOpen {
    my ($self, %params) = @_;
    my $uri = $params{textDocument}->{uri};
    my $document = Language::Server::Document->new(uri => $uri, text => $params{textDocument}->{text});
    $self->documents->{$uri} = $document;
    $self->log->tracef("Editor opened file %s", $uri);
    return;
}

sub initialize {
    my ($self, %params) = @_;
    $self->rootpath($params{rootUri});
    $self->plsense($params{initializedOptions}->{plense}) if ($params{initializedOptions}->{plense});
    my $ret = {
        capabilities => {

            # textDocumentSync => 0,
            textDocumentSync => 1, #full sync

            #  The server provides hover support.

            hoverProvider => \0,

            # completionProvider => CompletionOptions,
            # signatureHelpProvider => SignatureHelpOptions,
            definitionProvider        =>\1,
            referencesProvider        =>\0,
            documentHighlightProvider =>\0,

            documentSymbolProvider           =>\0,
            workspaceSymbolProvider          =>\0,
            codeActionProvider               =>\0,
            codeLensProvider                 =>\0,
            documentFormattingProvider       =>\1,
            documentRangeFormattingProvider  =>\1,
            documentOnTypeFormattingProvider => {},
            renameProvider                   =>\1

        }
    };
    return $ret;
}

sub didChange {
    my ($self, %params) = @_;
    $self->log->trace('didChange');

    # didChange returns full document change, at this time
    my $text = $params{contentChanges}->[0]->{text};
    my $doc  = $self->_get_document($params{textDocument}->{uri});
    $doc->text($text);
    # $doc->check;
}

sub didSave {
    my ($self, %params) = @_;
    $self->log->trace('didSave');
}

sub rename {
    my ($self, %params) = @_;
    $self->log->trace('rename');
    my $uri = $params{textDocument}->{uri};
    $self->log->trace("uri is $uri");

    my $line = $params{position}->{line} + 1;
    my $col  = $params{position}->{character};

    #TODO deal with multiples

    my $new_output;
    my $content = $self->_get_document_content($uri);

    $new_output = PPIx::EditorTools::RenameVariable->new->rename(
        code        => $content,
        column      => $col,
        line        => $line,
        replacement => $params{newName},
    )->code;

    my $ret = {
        changes => {
            $uri => [
                {
                    range => {
                        start => {line => 0,         character => 0},
                        end   => {line => 9_999_999, character => 0},
                    },
                    newText => $new_output,
                },
            ],
        }
    };
    return $ret;

    my @lines;

}

sub definition {
    my ($self, %params) = @_;
    $self->log->trace('definition');
    my $uri = $params{textDocument}->{uri};
    $self->log->trace("uri is $uri");

    my $line   = $params{position}->{line} + 1;
    my $column = $params{position}->{character};

    my $document = $self->_get_document($uri);
    my $editor   = Language::Server::Editor->new();
    my $result   = $editor->get_declaration($document, $line, $column);

    my $return = (defined $result)
        ? [     # Success
            {                                       # result
                uri   => $uri,
                range => {
                    start => {line => $result->{line}, character => $result->{column}},
                    end   => {line => $result->{line}, character => $result->{column}},
                },
            }
        ]
        : [     # Failure
            undef,                                  # result
            LSPErrorCode_InvalidParams,             # code
            'Failed to find the symbol defination', # message
            undef,                                  # data
        ];
    return @{$return};
}

sub formatting {
    my ($self, %params) = @_;
    $self->log->info(np(%params));
    my $uri = $params{textDocument}->{uri};
    if (!defined $uri) {
        return (0, -32602, 'uri is not set');
    }
    my $text     = $self->_get_document_content($uri);
    my $new_text = $self->tidy($text);

    my $ret = [
        {
            range => {
                start => {line => 0,         character => 0},
                end   => {line => 9_999_999, character => 0},
            },
            newText => $new_text,
        },
    ];
    return $ret;

}

sub range_formatting {
    my ($self, %params) = @_;

    my $uri = $params{textDocument}->{uri};
    if (!defined $uri) {
        return (0, -32602, 'uri is not set');
    }
    my $text          = $self->_get_document_content($uri);
    my @text_lines    = split("\n", $text);
    my @lines_to_tidy = $text_lines[$params{range}->{start}->{line} - 1 ... $params{range}->{end}->{line} - 1];
    my $new_text      = $self->tidy(join("\n", @lines_to_tidy));

    my $ret = [
        {
            range   => $params{range},
            newText => $new_text,
        },
    ];
    return $ret;
}

sub tidy {
    my ($self, $content) = @_;
    my $output;
    my $error_flag = Perl::Tidy::perltidy(
        source      => \$content,
        destination => \$output
    );
    chomp $output;
    $self->log->infof('Tidy:[%s]', $output);
    return $output;
}

sub _get_document_content {
    my ($self, $uri) = @_;
    return if (!defined $uri);
    return $self->_get_document($uri)->text;
}

sub _get_document {
    my ($self, $uri) = @_;
    my $document;
    return if (!defined $uri);
    if (defined $self->documents->{$uri}) {
        $document = $self->documents->{$uri};
    }
    else {
        $document = Language::Server::Document->new(uri => $uri);
        $self->documents->{$uri} = $document;
    }

    return $document;
}

sub didChangeConfiguration {
    my ($self, %params) = @_;
}
1;

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
use JSON;

use feature qw(state);

# use constant SELF=>class_type {class=>__PACKAGE__}; # Type::Type class self
with 'MooX::Log::Any';         # enable logger

# use namespace::autoclean;

#VERSION

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

has rootpath => (is => 'ro',);

sub didOpen {
    my ($self, %params) = @_;
    my $uri = $params{textDocument}->{uri};
    my $document = Language::Server::Document->new(uri => $uri, text => $params{textDocument}->{text});
    $self->documents->{$uri} = $document;
    $self->log->tracef("Editor opened file %s", $uri);
    return;
}

sub initialize {
    my ($self, $params) = @_;
    my $ret = {
        capabilities => {

            textDocumentSync => 1,

            #  The server provides hover support.

            hoverProvider => 0,

            # completionProvider => CompletionOptions,
            # signatureHelpProvider => SignatureHelpOptions,
            definitionProvider        => 0,
            referencesProvider        => 0,
            documentHighlightProvider => 0,

            documentSymbolProvider           => 0,
            workspaceSymbolProvider          => 0,
            codeActionProvider               => 0,
            codeLensProvider                 => 0,
            documentFormattingProvider       => 1,
            documentRangeFormattingProvider  => 1,
            documentOnTypeFormattingProvider => {},
            renameProvider                   => 1

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

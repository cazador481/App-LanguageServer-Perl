#ABSTRACT: Language::Server
package Language::Server;
use Moo;
use Types::Standard -types;
use Type::Utils qw(class_type);
use MooX::StrictConstructor;
use Data::Printer;
use Type::Params qw(compile);  #adds compile command for subroutine validation
use File::Slurp;
use IPC::Run3;
use PPIx::EditorTools::RenameVariable;

use feature qw(state);

# use constant SELF=>class_type {class=>__PACKAGE__}; # Type::Type class self
with 'MooX::Log::Any';         # enable logger

# use namespace::autoclean;

#VERSION

has file_content => (
    is        => 'rw',
    predicate => 1,
    lazy      => 1,
    default   => sub {
        my $self = shift;
        my $file = $self->file_uri;
        $file =~ s!file://!!;
        my $ret = read_file($file);
        return $ret;
    },

);

has value => (
    is      => 'rw',
    default => 0,
);

has file_uri => (
    is => 'rw',

    # coerce  => sub {print STDERR np @_;my $file = shift; print STDERR np($file);$file =~ s!^file://!!; return $file;},
);

sub didOpen
{
    my ($self, %params) = @_;
    my $uri = $params{textDocument}->{uri};
    $self->file_uri($uri);
    $self->file_content($params{textDocument}->{text});
    $self->log->tracef("Editor opened file %s", $self->file_uri);
    return;
}

sub initialize
{
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
            documentFormattingProvider       => 0,
            documentRangeFormattingProvider  => 0,
            documentOnTypeFormattingProvider => {},
            renameProvider                   => 1

        }
    };
    return $ret;
}

sub didChange
{
    my ($self, %params) = @_;
    $self->log->trace('didChange');

    #todo verify that this works
    $self->file_content($params{contentChanges}->[0]->{text});
}

sub didSave
{
    my ($self, %params) = @_;
    $self->log->trace('didSave');

}

sub rename
{
    my ($self, %params) = @_;
    $self->log->trace('rename');
    my $uri = $params{textDocument}->{uri};
    $self->log->trace("uri is $uri");

    my $line = $params{position}->{line} + 1;
    my $col  = $params{position}->{character};
    $self->log->trace("line:$line, col:$col");
    #TODO deal with multiples
    $self->file_uri($uri);

    my $new_output;
    my $content = $self->file_content;
    $self->log->error('File content empty') if !defined $self->file_content;

    $new_output = PPIx::EditorTools::RenameVariable->new->rename(
        code        => $content,
        column      => $col,
        line        => $line,
        replacement => $params{newName},
    )->code;

    my $ret = {
        changes => {
            $uri => [{
                range => {
                    start => {line => 0, character => 0},
                    end   => {line => 9999999, character => 0},
                },
                newText => $new_output,
            },
            ],
        }
    };
    return $ret;

    my @lines;

}
1;

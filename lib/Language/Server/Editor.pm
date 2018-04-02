package Language::Server::Editor;
# NOTE: Ideally this should be a singelton class, should be aware of configuration like
#       lib paths, perl version, environment variable, critic rc file, tidy rc file, etc.

use Language::Server::Document;
use PPIx::EditorTools::FindVariableDeclaration;
use Moo;

# TODO: Add support to find subroutine/method declaration
sub get_declaration {
    my ($self, $document, $line, $column) = @_;
    my ($declaration_line, $declaration_column) = (undef, undef);
    eval {
        # FIXME: Figure out if symbol under location($line, $column) is variable before finding variable declaration.
        my $declaration = PPIx::EditorTools::FindVariableDeclaration->new->find(
            code   => $document->text(),
            line   => $line,
            column => $column,
        );
        my $location = $declaration->element->location;

        # FIXME: we still get the accurate line number but column number is start of statement and not start of variable
        # NOTE: Subtracting 1 to make this a 0 indexed
        ($declaration_line, $declaration_column) = ($location->[0] - 1, $location->[1] - 1);
    } or do {

        # Failed to get the declaration
    };

    return (defined $declaration_line && defined $declaration_column)
      ? {line => $declaration_line, column => $declaration_column}
      : undef;
}

1;

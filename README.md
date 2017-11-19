# NAME

App::LanguageServer - Perl Language Server

# DESCRIPTION

App::LanguageServer is a language server based on the [Language Server Protocol](https://github.com/Microsoft/language-server-protocol/).
Currently App::LanguageServer supports a subset of v3.0 of the protocol.

More can be read about what a Language Server is for at [http://langserver.org](http://langserver.org)
but the idea is to allow editors/IDEs to support a variety of languages
without needing to reimplement lang-specific features themselves or,
as in most cases, not implementing them at all.

# FEATURES

* [Perl::Tidy](https://metacpan.org/pod/Perl::Tidy) full document formatting
* Variable renaming via [PPIx::EditorTools::RenameVariable](https://metacpan.org/pod/PPIx::EditorTools::RenameVariable)

#TODO

* Code completion via plsense
* Package renaming to match path
* Create make file
* linting via perl -c
* linting via perlcritic

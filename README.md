# NAME

App::LanguageServer - Perl Language Server

# DESCRIPTION

App::LanguageServer is a language server based on the [Language Server Protocol](https://github.com/Microsoft/language-server-protocol/).
Currently App::LanguageServer supports a subset of v3.0 of the protocol.

More can be read about what a Language Server is for at [http://langserver.org](http://langserver.org)
but the idea is to allow editors/IDEs to support a variety of languages
without needing to reimplement lang-specific features themselves or,
as in most cases, not implementing them at all.

# INSTALLATION

* `git clone https://github.com/cazador481/App-LanguageServer-Perl`
* `cd App-LanguageServer-Perl`
* `perl Build.PL`
* `sudo ./Build installdeps`
* To start the server 
    `perl bin/slp.pl`

# FEATURES

* [Perl::Tidy](https://metacpan.org/pod/Perl::Tidy) full document formatting, and range formatting
* Variable renaming via [PPIx::EditorTools::RenameVariable](https://metacpan.org/pod/PPIx::EditorTools::RenameVariable)
* linting via perl -c
* linting via perlcritic

# Installation instructions

This project is based on dzil.  To install the develoment version you need to run
* cpanm Dist::Zilla
* dzil listdepedencies | cpanm
* dzil install


# TODO

* Code completion via plsense
* Package renaming to match path path
* Make configurable via config file of some type
* Add some tests

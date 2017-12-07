#ABSTRACT Package thtat contains documents
package Language::Server::Document;
use Moo;
use Types::Standard -all;
use File::Slurp;
use AnyEvent::Util;
use AnyEvent;
use Data::Printer;
use Cpanel::JSON::XS;
use Language::Server::Config;
with 'MooX::Log::Any';

#VERSION

has _config => ( 
   is => 'rw',
   default=> sub {Language::Server::Config->instance},
   documentation=>'configuration',
);

has 'uri' => (
    is            => 'ro',
    isa           => Str,
    documentation => 'uri of file',
);

has 'text' => (
    is            => 'rw',
    isa           => Str,
    documentation => 'Document text',
    lazy          => 1,
    default       => sub {
        my $self = shift;
        my $file = $self->uri;
        $file =~ s!file://!!;
        my $ret = read_file($file);
        return $ret;
    },
    trigger => sub {
        my $self = shift;

        #reset the done_typing timer
        $self->_clear_done_typing_timer;
        $self->_done_typing_timer;
    },
);

has 'version' => (is => 'ro',);

#this code block contains the timer to  check to see if there is pause in typing.  On the pause the linter fires
has _done_typing_timer => (
    is      => 'rw',
    lazy    => 1,
    clearer => 1,
    default => sub {
        my $self = shift;
        AE::timer 1, 0, sub {
            if (!$self->last_run_check) {
                $self->check;
            }
            else {
                $self->_clear_done_typing_timer;
                $self->_done_typing_timer;
            }
        };
    },
);

has last_run_check => (
    is      => 'rw',
    default => 0,
);

has _running_check => (
    is      => 'rw',
    default => 0,
);

sub file {
    my $self      = shift;
    my $file_name = $self->uri;
    $file_name =~ s!^file://!!;
    return $file_name;
}

sub perlcompile {
    my ($self, $errors, $global_cv) = @_;
    my $text = $self->text;

    #cv must be defined 1 line before run_cmd to work
    my $cv;
    $cv = run_cmd(
        'perl -c -Ilib -Ilib/perl5',
        '<'  => \$text,
        '>'  => \my $stdout,
        '2>' => \my $stderr,
    );
    $cv->cb(
        sub {
            $self->log->tracef("perlcompile done:\nstdout:%s\nstderr:%s", $stdout, $stderr);
            if ($stdout !~ /^- syntax OK/) {
                foreach my $line (split('\n', $stderr)) {

                    #syntax error at - line 2, near "$ea4!"
                    if ($line =~ /^(.*) at (\S+) line (\d+),?(.*)/) {
                        my $error    = $1 . $4;
                        my $filename = $2;
                        my $line_num = $3 - 1;  #adjust line number to deal with mapping
                        $self->log->trace('error found');
                        if ($filename eq '-') {
                            $filename = $self->file;
                        }
                        push @$errors, {
                            range => {
                                start => {line => $line_num, character => 0},
                                end   => {line => $line_num, character => 0},
                            },

                            # severity => 1,
                            source  => 'perl -c',
                            message => $error,
                        };
                    }
                }

            }
            $global_cv->end;
        }
    );
}

sub perlcritic {
    my ($self, $errors, $global_cv) = @_;
    my $text = $self->text;

    my $verbosity = '%l:%c %m\n';

    #cv must be defined 1 line before run_cmd to work
    my $cv;
    $cv = run_cmd(
        "perlcritic --verbose '$verbosity' --nocolor",
        '<'  => \$text,
        '>'  => \my $stdout,
        '2>' => \my $stderr,
    );
    $cv->cb(
        sub {
            $self->log->tracef("perlcretic done:\nstdout:%s\nstderr:%s", $stdout, $stderr);
            if ($stdout !~ /^source OK/) {
                foreach my $line (split('\n', $stdout)) {

                    #syntax error at - line 2, near "$ea4!"
                    if ($line =~ /^(\d+):(\d+) (.*)$/) {
                        my $error    = $3;
                        my $filename = $self->file;
                        my $line_num = $1 - 1;      #adjust line number to deal with mapping
                        my $char     = $2 + 0;
                        $self->log->trace('error found');
                        push @$errors, {
                            range => {
                                start => {line => $line_num, character => $char},
                                end   => {line => $line_num, character => $char},
                            },

                            # severity => 1,
                            source  => 'perlcritic',
                            message => $error,
                        };
                    }
                }

            }
            $global_cv->end;
        }
    );
}

sub _send_rpc {
    my ($self, $hash) = @_;
    my $json   = to_json($hash);
    my $length = length(Encode::encode('UTF-8', $json));
    my $msg    = sprintf("Content-Length: %i\r\n\r\n%s\r\n", $length + 2, $json);
    print $msg;
    $self->log->tracef($msg);
}

sub check {
    my $self   = shift;
    my $errors = [];
    $self->last_run_check(time);
    $self->_running_check(1);
    my $cv = AnyEvent->condvar;
    $cv->begin;
    $cv->begin;
    $self->perlcritic($errors, $cv);
    $self->perlcompile($errors, $cv);

    $cv->recv;
    $self->_running_check(0);

    my $ret = {
        jsonrpc  => '2.0',
        'method' => 'textDocument/publishDiagnostics',
        params   => {
            uri         => $self->uri,
            diagnostics => $errors,
        },
    };
    $self->_send_rpc($ret);
}

1;

#ABSRACT: Plsense interface
package Language::Server::Plsense;
use Moo;
with 'MooX::Log::Any';
# VERSION
use Log::Any qw($log);

sub start {
    my $self=shift;
   $log->debug("PLSENSE starting"); 
   system('plsense svstart');
}
sub stop {
    my $self=shift;
   $log->debug("PLSENSE stoping"); 
   system('plsense svstop');
}

sub on_file {
    my ($self,$file)=@_;
    system("plsense -o $file");
}

sub code_add {
    my ($self, $lines) = @_;
    system("plsense codeadd " . join("\n", @$lines));
}

sub on_package {
    my ($self, $package) = @_;
            system("plsense onmod $package");
}

sub assist {
    my ($self,$data)=@_;
    my @completions = `plsense a $data`;
    return \@completions;
}
 1;

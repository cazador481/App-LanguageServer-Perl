package Language::Server::Document;
use Moo;
use Types::Standard -all;
use File::Slurp;

has 'uri' => ( 
   is => 'ro',
   isa => Str,
   documentation=>'uri of file',
);

has 'text' => ( 
   is => 'rw',
   isa => Str,
   documentation=>'Document text',
   lazy=>1,
   default   => sub {
        my $self = shift;
        my $file = $self->uri;
        $file =~ s!file://!!;
        my $ret = read_file($file);
        return $ret;
    },
);

has 'version' => ( 
   is => 'ro',
);

1;


package Language::Server::Config;
use Moo;
with 'MooX::Singleton';

has plsense => (is =>'rw',default=>1);
1;

use Test::More;  # qw(subtest)
use Test::Deep;  # qw(cmp_deeply)
use Language::Server::Editor qw();
use Language::Server::Document qw();

subtest "Testing subroutine 'get_declaration()'" => sub {
    my $test_file_uri = 'file://t/test_data/Foo.pm';
    my $document      = Language::Server::Document->new(uri => $test_file_uri);
    my @test_cases    = (
        {
            CASE   => 'Passing valid variable location is expected to return variable declaration location',
            INPUT  => [$document, 8, 33],
            OUTPUT => {
                line   => 6,
                column => 4,
            },
        },
        {
            CASE   => 'Passing invalid symbol location is expected to return undef',
            INPUT  => [$document, 7, 33],
            OUTPUT => undef,
        }
    );
    for my $test_case (@test_cases) {
        my $linter      = Language::Server::Editor->new();
        my $declaration = $linter->get_declaration(@{$test_case->{INPUT}});
        cmp_deeply($declaration, $test_case->{OUTPUT}, $test_case->{CASE});
    }
};

done_testing();

1;

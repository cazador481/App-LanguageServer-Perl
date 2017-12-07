use Test2::AsyncSubtest;
use Test2::Bundle::Extended;
use FindBin;
use lib "$FindBin::RealBin/../lib";
use strict;
use warnings;
use Test::Compile;
use Try::Tiny;
my $test = Test::Compile->new(verbose => 1);

my @files = all_pm_files();
my $ast = Test2::AsyncSubtest->new(name => 'ea');
my $test_being_run = 1;
foreach my $file (@files) {
    $test_being_run++;

    $ast->run_fork(
        sub {
            ok(test_module($file), "Compiling $file") or diag("Compile failure:$@");
        }
    );
    if ($test_being_run == 5) {
        $test_being_run = 0;
        $ast->wait;
    }
}
$ast->finish;
done_testing;

sub test_module {
    my $file = shift;
    if (-f $file) {
        my $module = $file;
        $module =~ s!^(blib[/\\])?lib[/\\]!!;
        $module =~ s![/\\]!::!g;
        $module =~ s/\.pm$//;

        return 1 if $module->require;

        return 0;
    }
    else {
        diag("$file could not be found");
        return 0;
    }
}


use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Mojo::File 'path';

# rss-reader.pl - RSS Reader. Pick episode to download.

use Test::ScriptX;


unlike(path('bin/rss-reader.pl')->slurp, qr{\<[A-Z]+\>},'All placeholders are changed');
my $t = Test::ScriptX->new('bin/rss-reader.pl', debug=>1);
$t->run(help=>1);
$t->stderr_ok->stdout_like(qr{rss-reader});
done_testing;

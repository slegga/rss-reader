use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Mojo::File 'path';

# rss-list.pl - An RSS reader. Read the last 20 rows. Can download. shell.

use Test::ScriptX;


unlike(path('bin/rss-list.pl')->slurp, qr{\<[A-Z]+\>},'All placeholders are changed');
my $t = Test::ScriptX->new('bin/rss-list.pl', debug=>1);
$t->run(help=>1);
$t->stderr_ok->stdout_like(qr{rss-list});
done_testing;

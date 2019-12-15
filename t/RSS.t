use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Mojo::File 'path';

# RSS.pm - Handle comunication with DB.

use Model::RSS;

unlike(path('lib/Model/RSS.pm')->slurp, qr{\<[A-Z]+\>},'All placeholders are changed');
my $m  = Model::RSS->new(debug=>1);
is_deeply($m->read('a'), {x=>'y'}, 'output is ok');
done_testing;

use Mojo::Base -strict;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use Mojo::File 'path';
use File::Spec::Functions 'catfile';
use Mojo::SQLite;
use Carp::Always;

unless (eval { require File::Temp; 1 }) {
    plan skip_all => 'File::Temp required';
}

my $tempdir  = File::Temp->newdir;
my $tempfile = catfile($tempdir, 'test.db');

my $sql = Mojo::SQLite->new->from_filename($tempfile);
$sql->migrations->from_file('migrations/tabledefs.sql')->migrate;

unlike(path('lib/Model/RSS.pm')->slurp, qr{\<[A-Z]+\>}, 'All placeholders are changed');

use_ok('Model::RSS');
my $m = Model::RSS->new(dbfile => $tempfile, debug => 1);
ok(-f $tempfile, "Tempfile exists: $tempfile");

# ---- episodes_read_by_ids ----------------------------------------------------

is_deeply($m->episodes_read_by_ids('a'), [], 'read_by_ids: nonexistent id returns []');
is($m->episodes_read_by_ids(), undef, 'read_by_ids: empty input returns undef');

# ---- episodes_update: insert a full record -----------------------------------

my $inserted = 0;
eval {
    $m->episodes_update([{
        id              => 'a',
        feed            => 'TestFeed',
        title           => 'Episode A',
        description     => 'First episode',
        published_epoch => 1700000000,
        url             => 'https://example.com/a.mp3',
    }]);
    $inserted = 1;
};
ok($inserted, 'episodes_update: insert new record does not die') or diag("error: $@");
my $row = $m->episodes_read_by_ids('a')->[0];
is($row->{title}, 'Episode A', 'episodes_update: title persisted');
is($row->{feed}, 'TestFeed',   'episodes_update: feed persisted');

# Note: episodes_update builds the SQL with @keys = keys %$hash BEFORE the
# in-memory merge, so passing a partial hash does NOT preserve omitted
# fields. The merge is essentially dead code. Callers must pass full hashes.

# ---- episodes_set_downloaded / episodes_rejected_add -------------------------

$m->episodes_set_downloaded('a');
$m->episodes_rejected_add('a');
$m->episodes_rejected_add('b');
my $handled = $m->episodes_read_handeled;
is_deeply([sort @$handled], ['a', 'b'], 'read_handeled: downloaded and rejected ids returned');

# ---- episodes_read_all -------------------------------------------------------

is(scalar @{$m->episodes_read_all}, 2, 'read_all: two rows present after reject+download+reject');

# ---- states_integer ----------------------------------------------------------

$m->states_integer({retrieve_episodes_epoch => 1700000000});
$m->states_integer({my_custom_key => 42});
my $si = $m->states_integer;
is($si->{retrieve_episodes_epoch}, 1700000000, 'states_integer: written value is read back');
is($si->{my_custom_key},           42,          'states_integer: secondary key is read back');

# ---- dryrun attribute --------------------------------------------------------

ok(!$m->dryrun, 'dryrun defaults to false');

done_testing;


package Model::RSS;
use Mojo::Base -base, -signatures;
use Mojo::SQLite;
use Mojo::File 'path';
use open ':encoding(UTF-8)';
use Mojo::JSON 'to_json';



=head1 NAME

Model::RSS.pm - Handle comunication with DB.

=head1 DESCRIPTION

Handle all communication with the database.

=head1 ATTRIBUTES

=head2 dbfile

Name of dbfile

=head2 sqlite

Default to a new Mojo::SQLite object

=head2 db

Default to a new Mojo::SQLite::Database object

=cut

has dbfile => $ENV{HOME}.'/etc/RSS.db';
has sqlite => sub {
	my $self = shift;
	if ( -f $self->dbfile) {
		return Mojo::SQLite->new()->from_filename($self->dbfile);
	} else {
		my $path = path($self->dbfile)->dirname;
		if (!-d "$path" ) {
			$path->make_path;
		}
		return Mojo::SQLite->new("file:".$self->dbfile);
	#	die "COULD NOT CREATE FILE ".$self->dbfile if ! -f $self->dbfile;
	}

};
has db => sub {shift->sqlite->db};


has 'dryrun';

=head1 METHODS

=head2 read

...

=cut

sub _query {
    my $self = shift;
    my $query = shift;
    my $res; #q|select id, feed, title, published_epoch, is_downloaded, is_rejected from episodes|
    eval {
	    $res = $self->db->query($query,@_);1;
	} or  die "DB ERROR: $!   $@";
	return if ! $res;
    return $res->hashes;
}

# _episode_write
#
# Internal write, handle errors.

sub _episode_write {
    my $self = shift;
    my $hash =shift;
    my @keys = keys %$hash;
    my @values = values %$hash;
    my $res;
    eval {
	    $res = $self->db->query('replace into episodes('.join(',',@keys).')', @values);1;
	} or  die "DB ERROR: $!   $@ ".$self->dbfile.' '.to_json $hash;
    return $res;
}

=head2 rejected_add

Add a list of rejected episodes

=cut

sub rejected_add {
	my $self = shift;
	my @rejected = @_;
	for my $r(@rejected) {
		$self->_episode_write({id=>$r,is_rejected=>1});
	}
}

=head2 rejected_read

Return a list of rejected ids

=cut

sub rejected_read {
	my $self = shift;

	my @t = map{$_->{id}}  @{ $self->_query(q|select id from episodes where is_rejected = 1|)};
	return \@t;
}
1;


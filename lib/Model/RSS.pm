package Model::RSS;
use Mojo::Base -base, -signatures;
use Mojo::SQLite;
use Mojo::File 'path';
use open ':encoding(UTF-8)';




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

sub read {
    my $self = shift;
    my $res = $self->db->query(q|select feed, title, published, is_downloaded, is_rejected from episode|);
    die $res->stderr if ($res->err);
    return $res->hashes->to_array;
}

=head2 write

=cut

sub write {
    my $self = shift;
    my $hash =shift;
    my @keys = keys %$hash;
    my @values = values %$hash;
    my $res = $self->db->query('replace into c('.join(',',@keys).')', @values);
    die $res->stderr if ($res->err);
}
1;

__END__

create table feeds (
id auto,
name text
);

create table episodes (
id auto,
id_feed integer,
name text,
description text,
downloaded boolean,
rejected boolean,
cached_value integer
);

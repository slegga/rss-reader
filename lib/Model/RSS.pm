package Model::RSS;
use Mojo::Base -base, -signatures;
use Mojo::SQLite;
use Mojo::File 'path';
use open ':encoding(UTF-8)';
use Mojo::JSON 'to_json';
#use Clone 'clone';


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
    my $query = 'replace into episodes('.join(',',@keys).') VALUES('.join(',',map{'?'}@values).')';
    say STDERR $query;
    eval {
	    $res = $self->db->query($query, @values);1;
	} or  die "DB ERROR: $!   $@ ".$self->dbfile.' '.to_json $hash;
    return $res;
}


=head2 episodes_update



=cut

sub episodes_update {
    my $self = shift;
    my $hashes =shift;
	my $res;
    for my $hash(@$hashes) {
	    my @keys = keys %$hash;
	    my @values = values %$hash;
	    if (grep {$_ eq 'id'} @keys) {
	    	my $old_hash = $self->episodes_by_ids($hash->{id})->[0];
	    	@$old_hash{keys %$hash} = values %$hash;
	    	$hash = $old_hash;
	    }
	    my $query = 'replace into episodes('.join(',',@keys).') VALUES('.join(',',map{'?'}@values).')';
	    say STDERR $query;
	    eval {
		    $res .= $self->db->query($query, @values);1;
		} or  die "DB ERROR: $!   $@ ".$self->dbfile.' '.to_json $hash;
	}
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

=head2 handeled_read

Return a list of rejected ids or downloaded ids.

=cut

sub handeled_read {
	my $self = shift;
	my @t = map{$_->{id}}  @{ $self->_query(q|select id from episodes where is_rejected = 1 or is_downloaded = 1|)};
	return \@t;
}
1;

=head2 episodes_by_ids

Get all episodes by id

=cut

sub episodes_by_ids {
	my $self = shift;
	my @ids = @_;
	return if ! @ids;
	return $self->_query('select * from episodes where id in ('.join(',',map {'?'}@ids).')',@ids);
}

=head2 downloaded_set

Register that episode is downloaded.

=cut

sub downloaded_set {
	my $self = shift;
	my @ids = @_;
}
#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use SH::ScriptX;
use Mojo::Base 'SH::ScriptX',-signatures;
use utf8;
use open ':encoding(UTF-8)';
use Mojo::Feed;
use Data::Dumper;
use Data::Printer;
use Model::RSS;
use Mojo::File 'path';
use Mojo::Promise;
use Clone 'clone';
# use XML::DOM::Parser;
use XML::DOM;
#use Carp::Always;

=head1 NAME

rss-reader.pl - RSS Reader. Pick episode to download.

=head1 DESCRIPTION

List 20 episodes. May mark some as downloaded or rejecteded.

=cut

option 'list=i',   'List the given best episodes. Default 7',{default=>7};
option 'dryrun!', 'Print to screen instead of doing changes';
has    'rss' => sub{Model::RSS->new};
option 'reject=s', 		'Comma separated list of episode ids which you do not want to listen to';
option 'download=s', 	'Comma separated list og episode ids which is going ';
option 'downloaddir=s', 'Dir to download to. Default /media/$ENV{USER}/USB DISK',{default=>"/media/$ENV{USER}/USB\\ DISK/"};
option 'update!',       'Force full update of database based on feeds';
#has    'downloadedrss' => sub {{vettogvitenskap =>'http://vettogvitenskap.libsyn.com/rss'}};
has    'rsses' => sub {return ['https://podkast.nrk.no/program/ekko_-_et_aktuelt_samfunnsprogram.rss'
    			, 'https://podkast.nrk.no/program/abels_taarn.rss'
#    			, 'https://rss.acast.com/teknopreik'
#    			, 'https://acast.aftenposten.no/rss/forklart'
    			, 'https://acast.aftenposten.no/rss/teknologimagasinet'
    			, 'https://acast.aftenposten.no/rss/foreldrekoden'
    			, 'https://acast.aftenposten.no/rss/sprekpodden'
#    			, 'http://api.vg.no/podcast/e24-podden.rss'
    			, 'https://www.tu.no/emne/podkast'
#    			, 'https://itunes.apple.com/no/podcast/game-at-first-sight/id1438153431'
    			, 'https://feed.pippa.io/public/shows/dobbeltklikk'
    			, 'http://vettogvitenskap.libsyn.com/rss'
    			, 'https://rss.podplaystudio.com/608.xml'
    			, 'https://feeds.acast.com/public/shows/30-minutter-inn-i-fremtiden'
    			, 'https://podkast.nrk.no/program/ukjent.rss'
    			]};
has    'rejected';
has    nore    => 300;

has states_integer => sub{$_[0]->rss->states_integer//{retrieve_episodes_epoch=>1000}};

#
# SUBS
#

sub get_new_episodes {
	my $self = shift;
	say "Update the database";
    my @unwanted = qw/antipanel reprise trær plante/;
    my %rejected = map{$_,1} @{$self->rss->episodes_read_handeled }; #get episodes that is either rejected or downloaded
	my $now = time();
    my @items;

    say Dumper $self->rejected;
    my $main_promise=Mojo::Promise->new;
    my $ioloop = $main_promise->ioloop;
    my $subprocess = $ioloop->subprocess;
    my @feed_p;
    for my $rss (@{$self->rsses}) {
        push @feed_p, $subprocess->run_p(
            sub {
    	        my $feed = Mojo::Feed->new(
    		    url => Mojo::URL->new($rss));
                say $rss;
                return $feed;
            }
        );
    }
#    p @feed_p;
    my @feeds;
    $main_promise->all(@feed_p)
    ->then(sub(@r){@feeds =map{clone($_)} grep {$_} @r;
    return @feeds;
    }
    )
    ->catch(sub($err){
        warn "Something went wrong: $err";
    })
    ->wait;

#    say "2" . (ref $feeds[0][0]||'__EMPTY2__');

#    p @feeds;

    for my $feed(@feeds) {
        say ref $feed;
        next if ! $feed;
        if ( ! ref $feed ) {
            p $feed;
            die "No ref";
        }
        if (ref $feed eq 'ARRAY') {
            # say $feed->[0];
        }
        if ( ref $feed ne 'Mojo::Feed' ) {
            say"ref is ". ref $feed;
            say "array num of items " .scalar @$feed;
            my $x = $feed->[0];
            say"ref2 is ". ref $x;
            if (! ref $feed->[0]) {
                $feed = Mojo::Feed->new(body => $x);
            } else {
                die $feed;
            }
#            die "No items method";

        }

#        say ref $feed;
#        p $feed;
        my $parser = new XML::DOM::Parser;
	    ITEM:
	    for my $raw($feed->items->head($self->nore)->each) {
	    	next if !$raw;
    		my $item;
	    	if (! $raw->can('published')) {
	    		p $raw;
	    		say STDERR  ref $raw;
	    		next;
	    	}
	    	if (! $raw->published) {
	    	    warn "Missing published";
	    	    p $raw;
	    	    my $doc = $parser->parse($raw->to_string);
	    	    my $nodes = $doc->getElementsByTagName ("CODEBASE");
	    	    my $n = $nodes->getLength;
	    	    say "LENGTH $n";
	    	    ...;

	    	}
	    	next if $self->states_integer->{'retrieve_episodes_epoch'} && $self->states_integer->{'retrieve_episodes_epoch'} > Mojo::Date->new($raw->published)->epoch;
	 		$item->{feed} = $feed->title;

	      	my $title = $raw->title;
	      	for my $x(@unwanted) {
	      		next if $title =~ /$x/i;
	      	}
	      	$item->{title} =  $raw->title;

			my $description = $raw->description;
	      	for my $x(@unwanted) {
	      		next ITEM if $description =~ /$x/i;
	      	}
			$item->{description} = $description;

			my $url = $raw->enclosures->to_array->[0];
			next if $url !~ /mp3/i;

			$item->{id} = $raw->id;
			next if  $rejected{$item->{id}};

			$url =~ s/.*url=\"//;
			$url =~ s/\".*//;
			$item->{url} =  "$url";
			$item->{published_epoch} = ref $raw->published ?  $raw->published->epoch : $raw->published ;
			push @items, $item;
	    }
    }
    # update database
	$self->rss->episodes_update(\@items);
	$self->states_integer($self->rss->states_integer({retrieve_episodes_epoch => $now}));
	return \@items;
}

 sub main {
    my $self = shift;
    my @e = @{ $self->extra_options };



    my @rsses = (
    			);

    if ($self->list) {
    	$self->nore(scalar $self->list);
    }
	if ($self->update){
		$self->nore(300);
		my $si = $self->states_integer;
		$si->{retrieve_episodes_epoch} = time - 4 * 30 * 24 * 60 * 60;
		$self->states_integer($si);
	}

 	$self->get_new_episodes if $self->states_integer->{retrieve_episodes_epoch}< time - 7*24*60*60 || $self->update; # update db

	if ($self->reject) {
		my @rejected = split (/\,/, $self->reject);
		$self->rss->episodes_rejected_add(@rejected);
		return $self->gracefull_exit;
	}
	if ($self->download) {
		my @downloaded = split (/\,/, $self->download);
		my @downepisodes = map {my $x =$_;$x=~s/wget //;$x} @{ $self->rss->episodes_read_by_ids(@downloaded) };
		my $cmd = 'wget -P '.$self->downloaddir.' '.join(' ',map {my $x =$_;$x=~s/wget //;$x} map{my $x=$_;$x=~s/\?.*//;$x} map {$_->{url}} @downepisodes) ;
		say $cmd;
		my $ret = eval {`$cmd`;1;} or die "$@;$! $cmd";
		say $ret;
		$self->rss->episodes_set_downloaded($_->{id}) for @downepisodes;
	#	}

		# rename duplicates
		my $path = $self->downloaddir;
		$path =~ s/\\//g;
		$path = path($path);
		my $downloadfiles = $path->list;
		for my $d(@{$downloadfiles->to_array}) {
		    if (-f "$d" && ! -s "$d") {
		        my $size = -s "$d";
		        die "File size for $d is $size. Media is probably full."
		    }
			my $basename = $d->basename;
			if($basename =~/^(.+)\.mp3\.(\d+)$/i) {
				my $newname = "$1.$2.mp3";
				if (-e $path->child($newname)->to_string) {
					$newname = "$1.$2.".int(rand(100000)).".mp3";
				}
				say "rename $basename to $newname";
				$d->move_to($path->child($newname));
			}
		}

		return $self->gracefull_exit;
	}

    if ($self->list) {
    	my @items = sort {$b->{published_epoch} <=> $a->{published_epoch}} grep{exists $_->{title} && $_->{title} && ! $_->{is_rejected} && ! $_->{is_downloaded}} @{ $self->rss->episodes_read_all };
	    for my $item(  @items[0 .. ($self->list -1)]) {
	    	say join(' ',$item->{id},Mojo::Date->new->epoch($item->{published_epoch})->to_string,$item->{feed});
	    	for my $key(qw/title description url/) {
	    		say $item->{$key};
	    	}
	    	say '--';
	    }
		return $self->gracefull_exit;
	}

	die "Must use options to do something";
}

__PACKAGE__->new(options_cfg=>{})->main();

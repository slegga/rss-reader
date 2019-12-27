#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use SH::ScriptX;
use Mojo::Base 'SH::ScriptX';
use utf8;
use open ':encoding(UTF-8)';
use Mojo::Feed;
use Data::Dumper;
use Data::Printer;
use Model::RSS;
#use Carp::Always;

=head1 NAME

rss-reader.pl - RSS Reader. Pick episode to download.

=head1 DESCRIPTION

List 20 episodes. May mark some as downloaded or rejecteded.

=cut

option 'list=i',   'List the given best episodes. Default 7',{default=>7};
option 'dryrun!', 'Print to screen instead of doing changes';
has 'rss' => sub{Model::RSS->new};
option 'reject=s', 		'Comma separated list of episode ids which you do not want to listen to';
option 'download=s', 	'Comma separated list og episode ids which is going ';


 sub main {
    my $self = shift;
    my @e = @{ $self->extra_options };
    my @unwanted = qw/antipanel reprise trær plante/;
    #my $old_date = Mojo::Date->new('2019-06-30T23:59:59+01:00')->epoch;
    my $old_date = Mojo::Date->new('Mon, 23 Sep 2019 10:30:00 GMT')->epoch;


	say "Update the database";

    my @rsses = ( 'https://podkast.nrk.no/program/ekko_-_et_aktuelt_samfunnsprogram.rss'
    			, 'https://podkast.nrk.no/program/abels_taarn.rss'
    			, 'https://rss.acast.com/teknopreik'
    			, 'https://acast.aftenposten.no/rss/forklart'
    			, 'https://acast.aftenposten.no/rss/teknologimagasinet'
    			, 'https://acast.aftenposten.no/rss/foreldrekoden'
    			, 'https://acast.aftenposten.no/rss/sprekpodden'
    			, 'http://api.vg.no/podcast/e24-podden.rss'
    			, 'https://www.tu.no/emne/podkast'
    			, 'https://itunes.apple.com/no/podcast/game-at-first-sight/id1438153431'
    			);
    my @items;
    my $nore = 300; # number of returned episodes
    if ($self->list) {
    	$nore = $self->list;
    }
    my %rejected = map{$_,1} @{$self->rss->handeled_read }; #get episodes that is either rejected or downloaded

    say Dumper \%rejected;
    for my $rss (@rsses) {
    	my $feed = Mojo::Feed->new(
    		url => $rss);
	    ITEM:
	    for my $raw($feed->items->head($nore)->each) {
	    	next if !$raw;
    		my $item;
	    	if (! $raw->can('published')) {
	    		p $raw;
	    		next;
	    	}
	    	next if $old_date > Mojo::Date->new($raw->published)->epoch;
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
			$item->{url} =  "wget $url";

			$item->{published} =  Mojo::Date->new($raw->published);
			push @items, $item;
	    }
    }
    # update database
	$self->rss->episodes_update(\@items);

	if ($self->reject) {
		my @rejected = split (/\,/, $self->reject);
		$self->rss->rejected_add(@rejected);
		return $self->gracefull_exit;
	}
	if ($self->download) {
		my @downloaded = split (/\,/, $self->download);
		my @downepisodes = @{ $self->rss->episodes_by_ids(@downloaded) };
		for my $d(@downepisodes) {
			my $cmd = 'wget '.$d->{url} ;
			my $ret = eval {`$cmd`;1;} or die "$@;$!";
			say $ret;
			$self->rss->downloaded_set($d);
		}
		return $self->gracefull_exit;
	}

    if ($self->list) {
	    for my $item(sort {$a->{published}->epoch <=> $b->{published}->epoch}  @items[0 .. ($nore-1)]) {
	    	say join(' ',$item->{id},$item->{published},$item->{feed});
	    	for my $key(qw/title description url/) {
	    		say $item->{$key};
	    	}
	    	say '--';
	    }
		$self->gracefull_exit;
	}

    for my $item(sort {$b->{published}->epoch <=> $a->{published}->epoch}  @items) {
    	say $item->{published}.'  '.$item->{feed};
    	for my $key(qw/title description url/) {
    		say $item->{$key};
    	}
    	say '--';
    }
}

__PACKAGE__->new(options_cfg=>{})->main();

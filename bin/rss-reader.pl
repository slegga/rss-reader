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
#use Carp::Always;

=head1 NAME

rss-reader.pl - RSS Reader. Pick episode to download.

=head1 DESCRIPTION

<DESCRIPTION>

=cut
option 'dryrun!', 'Print to screen instead of doing changes';


 sub main {
    my $self = shift;
    my @e = $self->extra_options;
    my @unwanted = qw/antipanel reprise trær plante/;
    #my $old_date = Mojo::Date->new('2019-06-30T23:59:59+01:00')->epoch;
    my $old_date = Mojo::Date->new('Mon, 23 Sep 2019 10:30:00 GMT')->epoch;
    my @rsses = qw /https://podkast.nrk.no/program/ekko_-_et_aktuelt_samfunnsprogram.rss https://podkast.nrk.no/program/abels_taarn.rss/;
    my @items;
    for my $rss (@rsses) {
    	my $feed = Mojo::Feed->new(
    		url => $rss);
    		my $item;
	    say $feed->title;
	    ITEM:
	    for my $raw($feed->items->head(300)->each) {
	    	next if $old_date > Mojo::Date->new($item->published)->epoch;
	    	say "--";

	      	my $title = $item->title;
	      	for my $x(@unwanted) {
	      		next if $title =~ /$x/i;
	      	}
	      	say $raw->title;

			my $description = $raw->description;
	      	for my $x(@unwanted) {
	      		next ITEM if $description =~ /$x/i;
	      	}
			say $description;

			my $url = $raw->enclosures->to_array->[0];
			$url =~ s/.*url=\"//;
			$url =~ s/\".*//;
			say "wget $url";

			say  Mojo::Date->new($raw->published);
			push @items, $item;
	    }
    }
}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();

use strict;
use StreamFinder::Apple;

my $podcast = new StreamFinder::Apple($ARGV[0]);

die "Invalid URL or no streams found!\n"  unless ($podcast);
my $firstStream = $podcast->get();
print "First Stream URL=$firstStream\n";
my $url = $podcast->getURL();
print "Stream URL=$url\n";
my $podcastTitle = $podcast->getTitle();
print "Title=$podcastTitle\n";
my $podcastDescription = $podcast->getTitle('desc');
print "Description=$podcastDescription\n";
my $podcastID = $podcast->getID();
print "PODCAST ID=$podcastID\n";
my $artist = $podcast->{'artist'};
print "Artist=$artist\n"  if ($artist);
my $genre = $podcast->{'genre'};
print "Genre=$genre\n"  if ($genre);
my $icon_url = $podcast->getIconURL();
if ($icon_url) {   #SAVE THE ICON TO A TEMP. FILE:
        my ($image_ext, $icon_image) = $podcast->getIconData();
        if ($icon_image && open IMGOUT, ">/tmp/${podcastID}.$image_ext") {
                binmode IMGOUT;
                print IMGOUT $icon_image;
                close IMGOUT;
        }
}
my $stream_count = $podcast->count();
print "--Stream count=$stream_count=\n";
my @streams = $podcast->get();
foreach my $s (@streams) {
        print "------ stream URL=$s=\n";
}
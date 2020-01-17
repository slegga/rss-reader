#!/usr/bin/env perl

use Mojo::Base -strict;;
use MP3::Tag;

my $mp3 = MP3::Tag->new($ARGV[0]);

# get some information about the file in the easiest way
say $_ for $mp3->autoinfo();


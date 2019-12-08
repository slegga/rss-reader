#!/usr/bin/env perl

use FindBin;
use lib "$FindBin::Bin/../../utilities-perl/lib";
use SH::UseLib;
use SH::ScriptX;
use Mojo::Base 'SH::ScriptX';
use utf8;
use open ':encoding(UTF-8)';
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
}

__PACKAGE__->new(options_cfg=>{extra=>1})->main();

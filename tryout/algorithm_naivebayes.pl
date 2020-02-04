#!/usr/bin/env perl
use Mojo::Base -strict;
use Algorithm::NaiveBayes;
use Data::Printer;
my $nb = Algorithm::NaiveBayes->new;

$nb->add_instance
  (attributes => {foo => 1, bar => 1, baz =>1},
   label => 'sports');

$nb->add_instance
  (attributes => {foo => 1, blurp => 1},
   label => ['sports', 'finance']);
$nb->add_instance
   (attributes => {bar => 1, baz => 1},
    label => ['dance']);

$nb->train;

# Find results for unseen instances
my $result = $nb->predict
  (attributes => {bar => 1, blurp => 1});

p $result;
#!/usr/bin/env perl6

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

my ML::TriesWithFrequencies::Trie ($tr1, $tr2);

$tr1 = trie-make(['bar'.comb]);
#say $tr1.Str;

$tr2 = trie-make(['bam'.comb]);
#say $tr2.Str;

my $tr3 = trie-merge($tr1, $tr2);
#say $tr3.toMapFormat;

my $tr4 = trie-insert( $tr3, ['balk'.comb]);
#say $tr4.toMapFormat;

my $tr5 = trie-create(<bar barman bask bell best>.map({[ $_.comb ]}) );
say $tr5.toMapFormat;
say $tr5.toWLFormat;

my $tr6 = trie-create-by-split(<bar barman bask bell best>);
say $tr6.toMapFormat;
say $tr6.toWLFormat;

say $tr5 eqv $tr6;

say trie-node-probabilities($tr5).toWLFormat;
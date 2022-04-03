#!/usr/bin/env perl6

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

say '-' x 120;

my $tr = trie-create-by-split( <bar barman bask bell best> );
trie-say($tr);

say '-' x 120;

my $ptr = trie-node-probabilities( $tr );
trie-say($ptr);

say '-' x 120;

say trie-node-probabilities(trie-create-by-split(<bar barman bask bell best>)).JSON;

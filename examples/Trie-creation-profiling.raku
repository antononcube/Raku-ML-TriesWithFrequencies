#!/usr/bin/env perl6

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

say "Now running Raku compiler: {$*RAKU.compiler.version}!";

my @words = slurp("/usr/share/dict/words".IO).lines;

say '@words.elems :', @words.elems;
say '@words.roll(12) :', @words.roll(12);

# Across a word collections sizes.
say "=" x 60;
say "Across word collections sizes";
say "=" x 60;

srand(12);
for [1..5].map({ 10 ** $_ }) -> $n {
    say '$n = ', $n;
    my @wordsLocal = $n > @words.elems ?? @words !! @words.roll($n) ;
    my $start = now;
    my ML::TriesWithFrequencies::Trie $tr = trie-create-by-split( @wordsLocal );
    say 'number of words = ', @wordsLocal.elems, ', creation time:', now - $start;
    say "Trie statistics: {trie-node-counts($tr).gist}";
    #say $tr.toWLFormat;
}

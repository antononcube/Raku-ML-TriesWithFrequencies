#!/usr/bin/env perl6

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

my ML::TriesWithFrequencies::Trie ($tr1, $tr2);

my @words = slurp("resources/dictionaryWords.txt".IO).lines;

say '@words.elems :', @words.elems;
say '@words.roll(12) :', @words.roll(12);

#`(
# Across a word bisection thresholds.
say "=" x 60;
say "Across a word bisection thresholds";
say "=" x 60;

srand(3232);
my @wordsLocal = @words.roll(10000);
my %thresholdTimings =
        do for [5, 10 ... 50] -> $th {
            say 'threshold = ', $th;
            my $start = now;
            my $tr = trie-create-by-split(@wordsLocal, bisection-threshold => $th);
            my $timing = now - $start;
            say 'creation time:', $timing;
            $th => $timing
        };

#put %thresholdTimings.pairs.sort({ $_.value });
put %thresholdTimings;
)

# Across a word collections sizes.
say "=" x 60;
say "Across a word collections sizes";
say "=" x 60;

srand(12);
for [1..5].map({ 10 ** $_ }) -> $n {
    say '$n = ', $n;
    my @wordsLocal = $n > @words.elems ?? @words.roll(@words.elems) !! @words.roll($n) ;
    my $start = now;
    my $tr = trie-create-by-split( @wordsLocal );
    say 'number of words = ', @wordsLocal.elems, ', creation time:', now - $start;
    #say $tr.toWLFormat;
}

use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

plan 4;

## 1
my @words1 = <bar bark bare cam came camelia>;
my $tr1 = ML::TriesWithFrequencies::Trie.create-by-split(@words1).node-probabilities;

isa-ok
        $tr1.leaf-probabilities,
        Hash,
        'Leaf probabilities are given as a hash';

## 2
is
        $tr1.leaf-probabilities.values.sum, 1,
        'Probabilities add to one';

## 2
my $tr2 = $tr1.retrieve(<b>);
is
        $tr2.leaf-probabilities.deepmap(* / $tr2.value).values.sum, 1,
        'Probabilities add to one over sub-tries';

## 3
is-deeply
        $tr1.retrieve('ba'.comb).leaf-probabilities,
        $tr1.retrieve('bar'.comb).leaf-probabilities,
        'Same leaf probabilities for different prefixes 1';

## 4
is-deeply
        $tr1.retrieve('ca'.comb).leaf-probabilities,
        $tr1.retrieve('cam'.comb).leaf-probabilities,
        'Same leaf probabilities for different prefixes 2';

done-testing;

use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

# The previous tests should have checked that these commands work and
# produce expected results:
my $tr = trie-create-by-split(<bar barman bark bask car cast first fist>);
my $ptr = trie-node-probabilities($tr);

## The commands above should produce the trie:
#TRIEROOT => 1
#├─b => 0.5
#│ └─a => 1
#│   ├─r => 0.75
#│   │ ├─k => 0.3333333333333333
#│   │ └─m => 0.3333333333333333
#│   │   └─a => 1
#│   │     └─n => 1
#│   └─s => 0.25
#│     └─k => 1
#├─c => 0.25
#│ └─a => 1
#│   ├─r => 0.5
#│   └─s => 0.5
#│     └─t => 1
#└─f => 0.25
#  └─i => 1
#    ├─r => 0.5
#    │ └─s => 1
#    │   └─t => 1
#    └─s => 0.5
#      └─t => 1

## With node counts:
# {Internal => 15, Leaves => 7, Total => 22}

plan 3;

## 1
is-deeply
        (trie-words($ptr, sep => '').Set (-) <first fist bar barman bark bask cast car>.Set).elems,
        0,
        'expected trie words 1';


## 2
is-deeply
        trie-words($ptr, sep => Whatever).sort,
        (("b", "a", "r"), ("b", "a", "r", "k"), ("b", "a", "r", "m", "a", "n"), ("b", "a", "s", "k"),
         ("c", "a", "r"), ("c", "a", "s", "t"), ("f", "i", "r", "s", "t"), ("f", "i", "s", "t")),
        'expected trie words 2';

## 3
is-deeply
        Hash(trie-words-with-probabilities($ptr, sep => '')),
        %((:cast(0.125e0), :car(0.125e0), :bask(0.125e0), :bar(0.375e0), :bark(0.125e0), :barman(0.125e0), :first(0.125e0), :fist(0.125e0))),
        'expected trie word probabilities';

done-testing;

use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

plan 7;

## 1
ok trie-create([['bar'.comb],]), 'make with one word';

## 2
isa-ok trie-create-by-split(['bar']).Str, Str, 'make with one word';

## 3
is-deeply trie-create-by-split(['bar']),
        trie-create([['bar'.comb],]),
        'equivalence of creation';

## 4
is-deeply
        trie-merge(trie-create([['bar'.comb],]), trie-create([['bar'.comb],])),
        trie-create-by-split(<bar bar>),
        'merge equivalence to creation-by-splitting';

## 5
ok trie-insert(trie-create-by-split('bar'), ['balk'.comb]),
        'insert test 1';

## 6
isa-ok trie-create-by-split(<bar bark balk cat cast>).toMapFormat,
        Hash,
        'to Map format test 1';

## 7
my $tr5 = trie-create(<bar barman bask bell best>.map({ [$_.comb] }));
my $tr6 = trie-create-by-split(<bar barman bask bell best>);
is-deeply
        $tr5,
        $tr6,
        'equivalence test';

done-testing;

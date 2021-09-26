use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

plan 11;

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
my @words5 = <bar barman bask bell best>;
my $tr5 = trie-create(@words5.map({ [$_.comb] }));
my $tr6 = trie-create-by-split(@words5);
is-deeply
        $tr5,
        $tr6,
        'equivalence test';

## 8
my @words7 = <bar barman bask car cast>;
my $tr7 = trie-create-by-split(@words7);
my $tr8 = trie-merge($tr5, $tr7);
is-deeply
        $tr5,
        trie-create-by-split(@words5),
        'same trie after merging 1';

## 9
is-deeply
        $tr7,
        trie-create-by-split(@words7),
        'same trie after merging 2';


## 10
my @words9 = <bar barman bask bask bask car cast>;
my $tr9 = trie-create-by-split(@words9);
my $tr10 = trie-merge($tr5, $tr9);
is-deeply
        $tr5,
        trie-create-by-split(@words5),
        'same trie after merging 3';

## 11
is-deeply
        $tr9,
        trie-create-by-split(@words9),
        'same trie after merging 4';

done-testing;

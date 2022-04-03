use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

plan 4;

## 1
is-deeply
        ML::TriesWithFrequencies::Trie.create-by-split('bar').insert('balk'.comb).hash,
        ML::TriesWithFrequencies::Trie.create-by-split(<bar balk>).hash,
        'create by split and insert';

## 2
my @words2 = <bar barman bask bell best>;
is-deeply
        ML::TriesWithFrequencies::Trie.create-by-split(@words2),
        trie-create-by-split(@words2),
        'create by split method vs create-by-split function';

## 3
my @words3 = <bar barman bask car cast>;
is-deeply
        ML::TriesWithFrequencies::Trie.create-by-split(@words2).merge(trie-create-by-split(@words3)).words(sep => '').sort,
        [|@words2, |@words3].unique.sort,
        'create by split, merge, get words';

## 4
is-deeply
        ML::TriesWithFrequencies::Trie.create-by-split([|@words2, |@words3]).shrink.remove-by-regex(rx/ ca .*/).words(sep => '').sort.grep(*.chars),
        ([|@words2, |@words3] (-) <car cast>).keys.unique.sort,
        'create by split, shrinl, remove by regex, get words';

done-testing;

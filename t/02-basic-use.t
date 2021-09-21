use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;


plan 2;

## 1
my $tr0 = trie-create-by-split(<bar barman bask bell best>);
isa-ok $tr0, ML::TriesWithFrequencies::Trie, 'created trie';

## 2
is-deeply
        trie-node-probabilities($tr0).toMapFormat,
        {:TROOT(${:TVALUE(1e0), :b(${:TVALUE(1e0), :a(${:TVALUE(0.6e0), :r(${:TVALUE(0.6666666666666666e0), :m(${:TVALUE(0.5e0), :a(${:TVALUE(1e0), :n(${:TVALUE(1e0)})})})}), :s(${:TVALUE(0.3333333333333333e0), :k(${:TVALUE(1e0)})})}), :e(${:TVALUE(0.4e0), :l(${:TVALUE(0.5e0), :l(${:TVALUE(1e0)})}), :s(${:TVALUE(0.5e0), :t(${:TVALUE(1e0)})})})})})},
        'node probabilities comparison';



done-testing;

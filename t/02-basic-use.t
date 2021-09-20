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
        { :TROOT(${ :TVALUE(1.0), :b(${ :TVALUE(1.0), :a(${ :TVALUE(0.6), :r(${ :TVALUE(<2/3>), :m(${ :TVALUE(0.5),
                                                                                                      :a(${
                                                                                                          :TVALUE(1.0),
                                                                                                          :n(${ :TVALUE(1.0) }) }) }) }),
                                                            :s(${ :TVALUE(<1/3>), :k(${ :TVALUE(1.0) }) }) }), :e(${
            :TVALUE(0.4), :l(${ :TVALUE(0.5), :l(${ :TVALUE(1.0) }) }), :s(${ :TVALUE(0.5),
                                                                              :t(${ :TVALUE(1.0) }) }) }) }) }) },
        'node probabilities comparison';



done-testing;

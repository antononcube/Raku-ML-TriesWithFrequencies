use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

# The previous tests should have checked that these commands work and
# produce expected results:
my $tr = trie-create-by-split(<bar barman bark bask bell best car cast call first fist fall fast>);
my $tr1 = trie-shrink($tr);

## The commands above should produce the trie:
# TRIEROOT => 13
# ├─b => 6
# │ ├─a => 4
# │ │ ├─r => 3
# │ │ │ ├─k => 1
# │ │ │ └─man => 1
# │ │ └─sk => 1
# │ └─e => 2
# │   ├─ll => 1
# │   └─st => 1
# ├─ca => 3
# │ ├─ll => 1
# │ ├─r => 1
# │ └─st => 1
# └─f => 4
#   ├─a => 2
#   │ ├─ll => 1
#   │ └─st => 1
#   └─i => 2
#     ├─rst => 1
#     └─st => 1

## With node counts:
# {Internal => 9, Leaves => 12, Total => 21}

plan 5;

## 1
# This only removes
is-deeply
        [trie-retrieve($tr1, <b a sk>).toMapFormat, trie-retrieve($tr1, <ca st>).toMapFormat],
        [{ :sk(${ :TRIEVALUE(1e0) }) }, { :st(${ :TRIEVALUE(1e0) }) }],
        'expected retrieval sub-tries';

## 2
# The tested command only removes the 'ca' branch:
# TRIEROOT => 13
# ├─REGREMOVED => 3
# ├─b => 6
# │ ├─a => 4
# │ │ ├─r => 3
# │ │ │ ├─k => 1
# │ │ │ └─man => 1
# │ │ └─sk => 1
# │ └─e => 2
# │   ├─ll => 1
# │   └─st => 1
# └─f => 4
#   ├─a => 2
#   │ ├─ll => 1
#   │ └─st => 1
#   └─i => 2
#     ├─rst => 1
#     └─st => 1
my $res1 = trie-remove-by-regex($tr1, / ^ 'ca' .* /, postfix => 'REGREMOVED');
is-deeply
        trie-retrieve($res1, <REGREMOVED>).toMapFormat,
        { :REGREMOVED(${ :TRIEVALUE(3e0) }) },
        "remove by regex / ^ 'ca' .* /";

## 3
# The tested command produces:
# TRIEROOT => 13
# ├─b => 6
# │ ├─a => 4
# │ │ └─r => 3
# │ │   ├─k => 1
# │ │   └─man => 1
# │ └─e => 2
# │   └─ll => 1
# ├─ca => 3
# │ ├─ll => 1
# │ └─r => 1
# └─f => 4
#   ├─a => 2
#   │ └─ll => 1
#   └─i => 2
#     └─rst => 1
my $res2 = trie-remove-by-regex($tr1, / ^ 's' .* /, postfix => '');
is-deeply
        trie-retrieve($res2, <b a sk>).toMapFormat,
        trie-retrieve($res2, <b a>).toMapFormat,
        "remove by regex / ^ 's' .* /";

## 4
is-deeply
        trie-select-by-regex($tr1, / ^ 'ca' .* /, postfix => ''),
        trie-remove-by-regex($tr1, / ^ 'ca' .* /, :invert, postfix => ''),
        'remove and select equivalence 1';

## 5
is-deeply
        trie-select-by-regex($tr1, / ^ 's' .* /, postfix => 'REGREMOVED'),
        trie-remove-by-regex($tr1, / ^ 's' .* /, :invert, postfix => 'REGREMOVED'),
        'remove and select equivalence 2';

done-testing;

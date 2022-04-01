use v6.d;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use Test;

# The tests below are adapted from the JavaTrie Mathematica tests in the file:
# https://github.com/antononcube/MathematicaForPrediction/blob/master/UnitTests/JavaTriesWithFrequencies-Unit-Tests.wlt

my @words = ["bark", "barkeeper", "barkeepers", "barkeep", "barks", "barking", "barked", "barker", "barkers"];

my @words2 = ["bar", "barring", "car", "care", "caress", "cold", "colder"];

plan 20;

# 1
my $jTr = trie-create-by-split(@words);
is $jTr.isa(ML::TriesWithFrequencies::Trie), True,
        'JavaTrieCreation1';

# 2
my $jTr2 = trie-create-by-split(@words2);
is $$jTr.isa(ML::TriesWithFrequencies::Trie), True,
        'JavaTrieCreation2';

# 3
is trie-create(@words>>.comb>>.List).isa(ML::TriesWithFrequencies::Trie), True,
        'JavaTrieCreation3';

# 4
is-deeply trie-create-by-split(@words).hash,
        trie-create(@words>>.comb>>.List).hash,
        'JavaTrieEqual1';

# 5
is (so $jTr.JSON.subst(/\s/, '').match(/'{"key":"TRIEROOT","value":9,' /)), True,
        'JavaTrieToJSON';

# 6
is-deeply <bark ba>.map({ trie-has-complete-match($jTr, $_.comb) }),
        (True, False),
        'JavaTrieHasCompleteMatchQ';

# 7
my $m7 = trie-shrink($jTr).JSON.match(:g, / '"key":' (.+?) <?before ','>/);
is-deeply $m7.values>>.[0]>>.Str.sort,
        ("\"TRIEROOT\"", "\"bark\"", "\"ing\"", "\"e\"", "\"d\"", "\"r\"", "\"s\"", "\"ep\"", "\"er\"", "\"s\"",
         "\"s\"").sort,
        'JavaTrieShrink1';

# 8
my $m8 = trie-shrink($jTr, sep => '~').JSON.match(:g, / '"key":' (.+?) <?before ','>/);
is-deeply $m8.values>>.[0]>>.Str.sort,
        ("\"TRIEROOT\"", "\"b~a~r~k\"", "\"i~n~g\"", "\"e\"", "\"r\"", "\"s\"", "\"d\"", "\"e~p\"", "\"e~r\"", "\"s\"",
         "\"s\"").sort,
        'JavaTrieShrink1';

# 9
is-deeply <barked balm barking>.map({ trie-contains($jTr, $_.comb) }),
        (True, False, True),
        'JavaTrieContains1';

# 10
is-deeply <barked balm barking>.map({ trie-has-complete-match($jTr, $_.comb) }),
        (True, False, True),
        'JavaTrieContains1';

# 11
is-deeply trie-words($jTr2, <b>, sep => '').sort,
        <bar barring>,
        'JavaTrieGetWords1';

# 12
is-deeply trie-words($jTr2, <c>, sep => '').sort,
        <cold colder car care caress>.sort,
        'JavaTrieGetWords2';

# 13
my $jTr3 = trie-merge($jTr, $jTr2);
is $jTr3.isa(ML::TriesWithFrequencies::Trie), True,
        'JavaTrieCreation4';

# 14
is-deeply trie-words($jTr3, sep => '').unique.sort,
        [|@words, |@words2].unique.sort,
        'JavaTrieGetWords3';

# 15
is-deeply trie-root-to-leaf-paths($jTr).sort,
        ($[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :e(6e0), :d(1e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :e(6e0), :e(3e0), :p(3e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :e(6e0), :e(3e0), :p(3e0), :e(2e0), :r(2e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :e(6e0), :e(3e0), :p(3e0), :e(2e0), :r(2e0), :s(1e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :e(6e0), :r(2e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :e(6e0), :r(2e0), :s(1e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :i(1e0), :n(1e0), :g(1e0)],
         $[:TRIEROOT(9e0), :b(9e0), :a(9e0), :r(9e0), :k(9e0), :s(1e0)]).Seq,
        'JavaRootToLeafPaths1';

# 16
is-deeply trie-words(trie-retrieve(trie-shrink($jTr), 'bark')).sort,
        (("bark",), ("bark", "s"), ("bark", "ing"), ("bark", "e", "d"),
         ("bark", "e", "r"), ("bark", "e", "r", "s"), ("bark", "e", "ep"),
         ("bark", "e", "ep", "er"), ("bark", "e", "ep", "er", "s")).sort,
        'JavaTrieShrinkAndGetWords1';

# 17
is-deeply trie-shrink($jTr).hash,
        trie-shrink($jTr).clone.hash,
        'JavaTrieCloneEquality1';

# 18
is-deeply
        <ba bar>.map({ trie-has-complete-match($jTr2, $_.comb) }),
        (False, True),
        'JavaTrieHasCompleteMatchQ1';

# 19
is-deeply
        trie-words($jTr, <b a r k>)>>.join.sort,
        trie-words(trie-node-probabilities($jTr), <b a r k>)>>.join.sort,
        'JavaTrieGetWords1';

# 20
is-deeply
        trie-words(trie-shrink($jTr)).sort,
        trie-words(trie-shrink(trie-node-probabilities($jTr))).sort,
        'JavaTrieGetWords1';

done-testing;

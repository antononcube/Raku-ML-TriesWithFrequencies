use Test;

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

# The previous tess should have checked that these commands work and
# produce expected results:
my @words = <bar barman>;
my $tr0 = trie-create-by-split(@words);

## The commands above should produce the trie:
# TRIEROOT => 2
# └─b => 2
#   └─a => 2
#     └─r => 2
#       └─m => 1
#         └─a => 1
#           └─n => 1

## With node counts:
# {Internal => 6, Leaves => 1, Total => 7}

plan 3;

## 1
my Str $wlFormat =
        '<|$TrieRoot -> <|$TrieValue -> 2, "b" -> <|$TrieValue -> 2, "a" ->
<|$TrieValue -> 2, "r" -> <|$TrieValue -> 2, "m" -> <|$TrieValue ->1,
"a" -> <|$TrieValue -> 1, "n" -> <|$TrieValue -> 1|>|>|>|>|>|>|>|>';

is-deeply
        $tr0.WL.subst(/\s/, ''):g,
        $wlFormat.subst(/\s/, ''):g,
        'Convert WL format';

## 2
my Str $jsonFormat =
        '{"key":"TRIEROOT", "value":2, "children":[{"key":"b", "value":2,
"children":[{"key":"a", "value":2, "children":[{"key":"r", "value":2, "children":[{"key":"m", "value":1,
"children":[{"key":"a", "value":1, "children":[{"key":"n", "value":1, "children":[]}]}]}]}]}]}]}';

is-deeply
        $tr0.JSON.subst(/\s/, ''):g,
        $jsonFormat.subst(/\s/, ''):g,
        'Convert JSON format';

## 3
my Str $xmlFormat = q:to/XMLEND/;
<TRIEROOT>
 <TRIEVALUE>2</TRIEVALUE>
 <b>
  <TRIEVALUE>2</TRIEVALUE>
  <a>
   <TRIEVALUE>2</TRIEVALUE>
   <r>
    <TRIEVALUE>2</TRIEVALUE>
    <m>
     <TRIEVALUE>1</TRIEVALUE>
     <a>
      <TRIEVALUE>1</TRIEVALUE>
      <n>
       <TRIEVALUE>1</TRIEVALUE>
      </n>
     </a>
    </m>
   </r>
  </a>
 </b>
</TRIEROOT>
XMLEND

is-deeply
        $tr0.XML.subst(/\s/, ''):g,
        $xmlFormat.subst(/\s/, ''):g,
        'Convert to XML format';

done-testing;

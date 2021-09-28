# Raku ML::TriesWithFrequencies


This Raku package has functions for creation and manipulation of 
[Tries (Prefix trees)](https://en.wikipedia.org/wiki/Trie) 
with frequencies.

The package provides Machine Learning (ML) functionalities, 
not "just" a Trie data structure.

This Raku implementation closely follows the Java implementation [AAp3].

The system of function names follows the one used in the Mathematica package [AAp2].

**Remark:** Below Mathematica and Wolfram Language (WL) are used as synonyms.

**Remark:** There is a Raku package with an alternative implementation, [AAp6], 
made mostly for comparison studies. (See the implementation notes below.) 
The package in this repository, `ML::TriesWithFrequencies`, is my *primary* 
Tries-with-frequencies package.

------

## Usage 

Consider a trie (prefix tree) created over a list of words:

```perl6
use ML::TriesWithFrequencies;
my $tr = trie-create-by-split( <bar bark bars balm cert cell> );
trie-say($tr);
```
```
# TRIEROOT => 6
# ├─b => 4
# │ └─a => 4
# │   ├─l => 1
# │   │ └─m => 1
# │   └─r => 3
# │     ├─k => 1
# │     └─s => 1
# └─c => 2
#   └─e => 2
#     ├─l => 1
#     │ └─l => 1
#     └─r => 1
#       └─t => 1
```

Here we convert the trie with frequencies above into a trie with probabilities:

```perl6
my $ptr = trie-node-probabilities( $tr );
trie-say($ptr);
```
```
# TRIEROOT => 1
# ├─b => 0.6666666666666666
# │ └─a => 1
# │   ├─l => 0.25
# │   │ └─m => 1
# │   └─r => 0.75
# │     ├─k => 0.3333333333333333
# │     └─s => 0.3333333333333333
# └─c => 0.3333333333333333
#   └─e => 1
#     ├─l => 0.5
#     │ └─l => 1
#     └─r => 0.5
#       └─t => 1
```

Here we shrink the trie with probabilities above:

```perl6
trie-say(trie-shrink($ptr));
```
```
# TRIEROOT => 1
# ├─ba => 0.6666666666666666
# │ ├─lm => 0.25
# │ └─r => 0.75
# │   ├─k => 0.3333333333333333
# │   └─s => 0.3333333333333333
# └─ce => 0.3333333333333333
#   ├─ll => 0.5
#   └─rt => 0.5
```

Here we retrieve a sub-trie with a key:

```perl6
trie-say(trie-retrieve($ptr, 'bar'.comb))
```
```
# r => 0.75
# ├─k => 0.3333333333333333
# └─s => 0.3333333333333333
```

------

## Representation

Each trie is tree of objects of the class `ML::TriesWithFrequencies::Trie`.
Such trees can be nicely represented as hash-maps. For example:

```perl6
say trie-shrink(trie-create-by-split(<core cort>)).toMapFormat;
```
```
# {TRIEROOT => {TRIEVALUE => 2, cor => {TRIEVALUE => 2, e => {TRIEVALUE => 1}, t => {TRIEVALUE => 1}}}}
```

The Hash-representation is used in the Mathematica package [AAp2].
Hence, such WL format is provided by the Raku package:

```perl6
say trie-shrink(trie-create-by-split(<core cort>)).WL;
```
```
# <|$TrieRoot -> <|$TrieValue -> 2, "cor" -> <|$TrieValue -> 2, "e" -> <|$TrieValue -> 1|>, "t" -> <|$TrieValue -> 1|>|>|>|>
```

------

## Implementation notes

This package is a Raku re-implementation of the Java Trie package [AAp3].

The initial implementation was:
- ≈ 5-6 times slower than the Mathematica implementation [AAp2]
- ≈ 100 times slower than the Java implementation [AAp3]

The initial implementation used:
- General types for Trie nodes, i.e. `Str` for the key and `Numeric` for the value
- Argument type verification with `where` statements in the signatures of the `trie-*` functions

After reading [RAC1] I refactored the code to use native types (`num`, `str`)
and moved the `where` verifications inside the functions. 

I also refactored the function `trie-merge` to use less copying of data and
to take into account which of the two tries has smaller number of children.

After those changes the current Raku implementation is:
- ≈ 2.5 times slower than the Mathematica implementation [AAp2]
- ≈ 40 times slower than the Java implementation [AAp3]

These speed improvements are definitely not satisfactory. I strongly consider:

1. Re-implementing in Raku the Mathematica  package [AAp2], i.e. to move into Tries that are hashes.

   - (It turned out option 1 does not produce better results; see [AAp6].)
  
2. Re-implementing in C or C++ the Java package [AAp3] and hooking it up to Raku.


------

## TODO

In the following list the most important items are placed first.

- [ ] Implement "get words" and "get root-to-leaf paths" functions.

- [ ] Convert most of the WL unit tests in [AAp5] into Raku tests.

- [ ] Implement Trie traversal functions.

- [ ] Implement Trie-based classification.
  
- [ ] Implement sub-trie removal functions.
  
- [ ] Investigate faster implementations.
 
  - [X] Re-implement the Trie functionalities using hash representation (instead of a tree of Trie-node objects.)
    
     - See [AAp6].
  
  - [ ] Make a C or C++ implementation and hook it up to Raku.  
    
- [ ] Document examples of doing Trie-based text mining or data-mining.

- [ ] Program a trie-form visualization that is "wide", i.e. places the children nodes horizontally.

------

## References

### Articles

[AA1] Anton Antonov,
["Tries with frequencies for data mining"](https://mathematicaforprediction.wordpress.com/2013/12/06/tries-with-frequencies-for-data-mining/),
(2013),
[MathematicaForPrediction at WordPress](https://mathematicaforprediction.wordpress.com).

[AA2] Anton Antonov,
["Removal of sub-trees in tries"](https://mathematicaforprediction.wordpress.com/2014/10/12/removal-of-sub-trees-in-tries/),
(2013),
[MathematicaForPrediction at WordPress](https://mathematicaforprediction.wordpress.com).

[AA3] Anton Antonov,
["Tries with frequencies in Java"](https://mathematicaforprediction.wordpress.com/2017/01/31/tries-with-frequencies-in-java/),
(2017),
[MathematicaForPrediction at WordPress](https://mathematicaforprediction.wordpress.com).
[GitHub Markdown](https://github.com/antononcube/MathematicaForPrediction).

[RAC1] Tib,
["Day 10: My 10 commandments for Raku performances"](https://raku-advent.blog/2020/12/10/day-10-my-10-commandments-for-raku-performances/),
(2020),
[Raku Advent Calendar](https://raku-advent.blog).

[WK1] Wikipedia entry, [Trie](https://en.wikipedia.org/wiki/Trie).

### Packages

[AAp1] Anton Antonov, 
[Tries with frequencies Mathematica Version 9.0 package](https://github.com/antononcube/MathematicaForPrediction/blob/master/TriesWithFrequenciesV9.m),
(2013), 
[MathematicaForPrediction at GitHub](https://github.com/antononcube/MathematicaForPrediction).

[AAp2] Anton Antonov,
[Tries with frequencies Mathematica package](https://github.com/antononcube/MathematicaForPrediction/blob/master/TriesWithFrequencies.m),
(2013-2018),
[MathematicaForPrediction at GitHub](https://github.com/antononcube/MathematicaForPrediction).

[AAp3] Anton Antonov, 
[Tries with frequencies in Java](https://github.com/antononcube/MathematicaForPrediction/tree/master/Java/TriesWithFrequencies), 
(2017),
[MathematicaForPrediction at GitHub](https://github.com/antononcube/MathematicaForPrediction).

[AAp4] Anton Antonov, 
[Java tries with frequencies Mathematica package](https://github.com/antononcube/MathematicaForPrediction/blob/master/JavaTriesWithFrequencies.m), 
(2017),
[MathematicaForPrediction at GitHub](https://github.com/antononcube/MathematicaForPrediction).

[AAp5] Anton Antonov, 
[Java tries with frequencies Mathematica unit tests](https://github.com/antononcube/MathematicaForPrediction/blob/master/UnitTests/JavaTriesWithFrequencies-Unit-Tests.wlt), 
(2017), 
[MathematicaForPrediction at GitHub](https://github.com/antononcube/MathematicaForPrediction).

[AAp6] Anton Antonov,
[ML::HashTriesWithFrequencies Raku package](https://github.com/antononcube/Raku-ML-HashTriesWithFrequencies),
(2021),
[GitHub/antononcube](https://github.com/antononcube).


### Videos

[AAv1] Anton Antonov,
["Prefix Trees with Frequencies for Data Analysis and Machine Learning"](https://www.youtube.com/watch?v=MdVp7t8xQbQ),
(2017),
Wolfram Technology Conference 2017,
[Wolfram channel at YouTube](https://www.youtube.com/channel/UCJekgf6k62CQHdENWf2NgAQ).

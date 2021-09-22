# Raku ML::TriesWithFrequencies


This Raku package has functions for creation and manipulation of tries (prefix trees) with frequencies.

The package objects and functions should be seen as Machine Learning (ML) artifacts, 
not "just" data structure ones.

The Trie functionalities implementation of this Raku package closely follows the Java implementation [AAp3].

------

## Usage 

Consider a trie (prefix tree) created over a list of words:

```perl6
use ML::TriesWithFrequencies;
my $tr = trie-create-by-split( <bar bark bars balm cert cell> );
trie-say($tr);
```

Here we convert the trie with frequencies above into a trie with probabilities:

```perl6
my $ptr = trie-node-probabilities( $tr );
trie-say($ptr);
```

Here we shrink the trie with probabilities above:

```perl6
trie-say(trie-shrink($ptr));
```

Here we retrieve a sub-trie with a key:

```perl6
trie-say(trie-retrieve($ptr, 'bar'.comb))
```

------

## Representation

Each trie is tree of objects of the class `ML::TriesWithFrequencies::Trie`.
Such trees can be nicely represented as hash-maps. For example:

```perl6
say trie-shrink(trie-create-by-split(<core cort>)).toMapFormat;
```

On such representation is based the Trie functionalities implementations of the Mathematica package [AAp2].
Hence, such WL format is provided by the package:

```perl6
say trie-shrink(trie-create-by-split(<core cort>)).toWLFormat;
```

------

## Implementation notes

This Raku package is a Raku re-implementation of the Java Trie package [AAp3].

The initial implementation was:
- 5-6 times slower than the Mathematica implementation [AAp2]
- 100 times slower than the Java implementation [AAp3]

The initial implementation used:
- General types for Trie nodes, i.e. `Str` for the key and `Numeric` for the value
- Argument type verification `where` statements in the `trie-*` functions

After reading [RAC1] I refactored the code to use native types and moved the `where` verifications
inside the functions. 

After those changes the current Raku implementation is:
- 4 times slower than the Mathematica implementation [AAp2]
- 70 times slower than the Java implementation [AAp3]

These speed improvements are definitely not satisfactory. I strongly consider:
- Re-implementing in Raku the Mathematica  package [AAp2], i.e. to move into Tries that are hashes
- Re-implementing in C or C++ the Java package [AAp3] and hooking it up to Raku


------

## TODO

Most import TODO items are places first.

- [ ] Implement "get words" and "get root-to-leaf paths" functions

- [ ] Convert most of the WL unit tests in [AAp5] into Raku tests.

- [ ] Implement Trie traversal functions.

- [ ] Implement Trie-based classification.
  
- [ ] Implement sub-trie removal functions.
  
- [ ] Investigate faster implementations.
 
  - [ ] Re-implement the Trie functionalities using hash representation for a Trie (instead of a tree of Trie node objects.)
  
  - [ ] Make a C or C++ implementation and hook-it up to Raku.  
    
- [ ] Document examples of using Trie text mining to derive grammars.
  
- [ ] Make trie-form visualization that is "wide", i.e. places the children nodes horizontally.

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
["Tries with frequencies in Java"](https://mathematicaforprediction.wordpress.com/2017/01/31/tries-with-frequencies-in-java/)
(2017),
[MathematicaForPrediction at WordPress](https://mathematicaforprediction.wordpress.com).
[GitHub Markdown](https://github.com/antononcube/MathematicaForPrediction).

[RAC1] Tib,
["Day 10: My 10 commandments for Raku performances"](https://raku-advent.blog/2020/12/10/day-10-my-10-commandments-for-raku-performances/),
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


### Videos

[AAv1] Anton Antonov,
["Prefix Trees with Frequencies for Data Analysis and Machine Learning"](https://www.youtube.com/watch?v=MdVp7t8xQbQ),
(2017),
Wolfram Technology Conference 2017,
[Wolfram channel at YouTube](https://www.youtube.com/channel/UCJekgf6k62CQHdENWf2NgAQ).
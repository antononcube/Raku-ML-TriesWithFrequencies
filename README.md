# Raku ML::TriesWithFrequencies


This Raku package has functions for creation and manipulation of tries (prefix trees) with frequencies.

The package objects and functions should be seen as Machine Learning (ML) artifacts, 
not "just" data structure ones.

## Usage 

Consider a trie (prefix tree) created over a list of words:

```perl6
use ML::TriesWithFrequencies;
my $tr = trie-create-by-split( <bar bark bars balm cert cell> );
trie-form($tr);
```
```
# TRIEROOT
# ├─6
# ├─b
# │ ├─4
# │ └─a
# │   ├─4
# │   ├─l
# │   │ ├─1
# │   │ └─m
# │   │   └─1
# │   └─r
# │     ├─3
# │     ├─k
# │     │ └─1
# │     └─s
# │       └─1
# └─c
#   ├─2
#   └─e
#     ├─2
#     ├─l
#     │ ├─1
#     │ └─l
#     │   └─1
#     └─r
#       ├─1
#       └─t
#         └─1
```

Here we convert the trie with frequencies above into a trie with probabilities:

```perl6
my $ptr = trie-node-probabilities( $tr );
trie-form($ptr);
```
```
# TRIEROOT
# ├─1
# ├─b
# │ ├─0.6666666666666666
# │ └─a
# │   ├─1
# │   ├─l
# │   │ ├─0.25
# │   │ └─m
# │   │   └─1
# │   └─r
# │     ├─0.75
# │     ├─k
# │     │ └─0.3333333333333333
# │     └─s
# │       └─0.3333333333333333
# └─c
#   ├─0.3333333333333333
#   └─e
#     ├─1
#     ├─l
#     │ ├─0.5
#     │ └─l
#     │   └─1
#     └─r
#       ├─0.5
#       └─t
#         └─1
```

Here we shrink the trie with probabilities above:

```perl6
trie-form(trie-shrink($ptr));
```
```
# TRIEROOT
# ├─1
# ├─ba
# │ ├─0.6666666666666666
# │ ├─lm
# │ │ └─0.25
# │ └─r
# │   ├─0.75
# │   ├─k
# │   │ └─0.3333333333333333
# │   └─s
# │     └─0.3333333333333333
# └─ce
#   ├─0.3333333333333333
#   ├─ll
#   │ └─0.5
#   └─rt
#     └─0.5
```

Here we retrieve a sub-trie with a key:

```perl6
trie-form(trie-retrieve($ptr, 'bar'.comb))
```
```
# r
# ├─0.75
# ├─k
# │ └─0.3333333333333333
# └─s
#   └─0.3333333333333333
```

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

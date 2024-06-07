# Raku ML::TriesWithFrequencies
  
[![MacOS](https://github.com/antononcube/Raku-ML-TriesWithFrequencies/actions/workflows/macos.yml/badge.svg)](https://github.com/antononcube/Raku-ML-TriesWithFrequencies/actions/workflows/macos.yml)
[![Linux](https://github.com/antononcube/Raku-ML-TriesWithFrequencies/actions/workflows/linux.yml/badge.svg)](https://github.com/antononcube/Raku-ML-TriesWithFrequencies/actions/workflows/linux.yml)
[![Win64](https://github.com/antononcube/Raku-ML-TriesWithFrequencies/actions/workflows/windows.yml/badge.svg)](https://github.com/antononcube/Raku-ML-TriesWithFrequencies/actions/workflows/windows.yml)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)
[![https://raku.land/zef:antononcube/ML::TriesWithFrequencies](https://raku.land/zef:antononcube/ML::TriesWithFrequencies/badges/version)](https://raku.land/zef:antononcube/ML::TriesWithFrequencies)
[![https://raku.land/zef:antononcube/ML::TriesWithFrequencies](https://raku.land/zef:antononcube/ML::TriesWithFrequencies/badges/downloads)](https://raku.land/zef:antononcube/ML::TriesWithFrequencies)

This Raku package has functions for creation and manipulation of 
[Tries (Prefix trees)](https://en.wikipedia.org/wiki/Trie) 
with frequencies.

The package provides Machine Learning (ML) functionalities, 
not "just" a Trie data structure.

This Raku implementation closely follows the Java implementation [AAp3].

The subset of functions with the prefix "trie-" follows the one used in the Mathematica package [AAp2].
That is the "top-level" sub-system of function names; the sub-system is follows the typical Object-Oriented Programming (OOP)
Raku style.

**Remark:** Below Mathematica and Wolfram Language (WL) are used as synonyms.

**Remark:** There is a Raku package with an alternative implementation, [AAp6], 
made mostly for comparison studies. (See the implementation notes below.) 
The package in this repository, `ML::TriesWithFrequencies`, is my *primary* 
Tries-with-frequencies package.

-------

## Installation

Via zef-ecosystem:

```
zef install ML::TriesWithFrequencies
```

From GitHub:

```
zef install https://github.com/antononcube/Raku-ML-TriesWithFrequencies
```

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

Here is a "dot-pipeline" that combines the steps above: 

```perl6
<bar bark bars balm cert cell>.&trie-create-by-split
.node-probabilities
.shrink
.retrieve(<ba r>)        
.form
```

**Remark:** In the pipeline above we retrieve with `<ba r>`, not with `<b a r>`, 
because the trie is already shrunk.


The package provides a fair amount of functions in order to facilitate ML applications. 
In support of that statement, here are the methods of `ML::TriesWithFrequencies::Trie`:

```perl6
ML::TriesWithFrequencies::Trie.^method_names
```

Generate random words using trie, make a new trie, and visualize it:

```perl6
my @randomWords = $ptr.random-choice(200):drop-root;
my $ptrRandom = trie-create(@randomWords).node-probabilities;
$ptrRandom.form;
```

Compare with the original one:

```perl6
$ptr.form
```

**Remark:** It is expected with large numbers of generated words to get frequencies 
very close to those of the original trie.

------

## Representation

Each trie is a tree of objects of the class `ML::TriesWithFrequencies::Trie`.
Such trees can be nicely represented as hash-maps. For example:

```perl6
my $tr = trie-shrink(trie-create-by-split(<core cort>));
say $tr.gist;
```

The function `trie-say` uses that Hash-representation:

```perl6
trie-say($tr)
```

### JSON

The JSON-representation follows the inherent object-tree
representation with `ML::TriesWithFrequencies::Trie`:

```perl6
say $tr.JSON;
```

### XML

The XML-representation follows (resembles) the Hash-representation 
(and output from `trie-say`):

```perl6
say $tr.XML;
```

Using the XML representation allows for 
[XPath](https://www.w3schools.com/xml/xml_xpath.asp)
searches, say, using the package 
[`XML::XPath`](https://github.com/ufobat/p6-XML-XPath).
Here is an example:

```perl6
use XML::XPath;
my $tr0 = trie-create-by-split(<bell best>);
trie-say($tr0);
```
Convert to XML:

```perl6
say $tr0.XML;
```

Search for `<b e l>`:

```perl6
say XML::XPath.new(xml=>$tr0.XML).find('//b/e/l');
```

### WL

The Hash-representation is used in the Mathematica package [AAp2].
Hence, such WL format is provided by the Raku package:

```perl6
say $tr.WL;
```

------

## Cloning 

All `trie-*` functions and `ML::TriesWithFrequencies::Trie` methods that manipulate tries produce trie clones.

For performance reasons I considered having in-place trie manipulations, but that, of course, confuses reasoning
in development, testing, and usage. Hence, ubiquitous cloning.

------

## Two stiles of pipelining

As it was mentioned above the package was initially developed to have the functional programming design 
of the Mathematica package [AAp2]. With that design and using the 
[feed operator `==>`](https://docs.raku.org/language/operators#infix_==%3E)
we can construct pipelines like this one:

```perl6
my @words2 = <bar barman bask bell belly>;
my @words3 = <call car cast>;

trie-create-by-split(@words2)==>
trie-merge(trie-create-by-split(@words3))==>
trie-node-probabilities==>
trie-shrink==>
trie-say
```

The package also supports "dot pipelining" through chaining of methods:

```perl6
@words2.&trie-create-by-split
        .merge(@words3.&trie-create-by-split)
        .node-probabilities
        .shrink
        .form
```

**Remark:** The `trie-*` functions are implemented through the methods of `ML::TriesWithFrequencies::Trie`.
Given the method the corresponding function is derived by adding the prefix `trie-`. 
(For example, `$tr.shrink` vs `trie-shrink($tr)`.) 

Here is the previous pipeline re-written to use only methods of `ML::TriesWithFrequencies::Trie`:

```{perl6, eval=FALSE}
ML::TriesWithFrequencies::Trie.create-by-split(@words2)
        .merge(ML::TriesWithFrequencies::Trie.create-by-split(@words3))
        .node-probabilities
        .shrink
        .form
```

------

## Implementation notes

### UML diagram

Here is a UML diagram that shows package's structure:

```perl6, output.lang=mermaid, output.prompt=NONE
use UML::Translators;
to-uml-spec('ML::TriesWithFrequencies', format => 'mermaid')
```

**Remark:** The function `to-uml-spec` is provided by the package ["UML::Translators"](https://raku.land/zef:antononcube/UML::Translators), [AAp7].


### Performance

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

After the (monumental) work on 
[the new MoarVM dispatch mechanism](https://6guts.wordpress.com/2021/09/29/the-new-moarvm-dispatch-mechanism-is-here/),
[JW1], was incorporated in standard Rakudo releases (September/October 2021)
additional 20% speed-up was obtained. Currently this package is:
- ≈ 2.0 times slower than the Mathematica implementation [AAp2]
- ≈ 30 times slower than the Java implementation [AAp3]

These speed improvements are definitely not satisfactory. I strongly consider:

1. Re-implementing in Raku the Mathematica package [AAp2], i.e. to move into Tries that are hashes.

   - (It turned out option 1 does not produce better results; see [AAp6].)
  
2. Re-implementing in C or C++ the Java package [AAp3] and hooking it up to Raku.

### Moving from FP design and OOP design

The initial versions of the package -- up to version 0.5.0 -- had exported functions only 
in the namespace `ML::TriesWithFrequencies` with the prefix `trie-`. 
Those functions came from a purely Functional Programming (FP) design.

In order to get chains of OOP methods application that 
are typical in Raku programming the package versions after version 0.6.0 and later have trie 
manipulation transformation methods in the class `ML::TriesWithFrequencies::Trie`. 

In order to get trie-class methods a fairly fundamental code refactoring was required. 
Here are the steps:

1. The old class `ML::TriesWithFrequencies::Trie` was made into the role
   `ML::TriesWithFrequencies::Trieish`.

2. The traversal and remover classes were made to use `ML::TriesWithFrequencies::Trieish` type
instead of `ML::TriesWithFrequencies::Trie`.

3. The trie functions implementations -- with the prefix "trie-" -- 
of `ML::TriesWithFrequencies` were moved as methods implementations in `ML::TriesWithFrequencies::Trie`.

4. The trie functions in `ML::TriesWithFrequencies` were reimplemented using the methods
of `ML::TriesWithFrequencies::Trie`.

**Remark:** See the section "Two stiles of pipelining" above for illustrations of the two approaches.

------

## TODO

In the following list the most important items are placed first.

- [X] DONE Implement "get words" and "get root-to-leaf paths" functions.
     
     - See `trie-words` and `trie-root-to-leaf-paths`.
     
- [X] DONE Convert most of the WL unit tests in [AAp5] into Raku tests.

- [X] DONE Implement Trie traversal functions.

     - The general `trie-map` function is in a separate role.
        
     - A concrete traversal functionality is a class that does the role 
       and provides additional context.
       
- [X] DONE Implement (sub-)trie removal functions.

     - [X] DONE By threshold (below and above)
    
     - [X] DONE By Pareto principle adherence (top and bottom)
    
     - [X] DONE By regex over the keys

- [ ] TODO Implement optional ULP spec argument for relevant functions:
     
     - [X] DONE `trie-root-to-leaf-paths`
     
     - [X] DONE `trie-words`
     
     - [ ] TODO Membership test functions?
     
- [X] DONE Design and code refactoring so trie objects to have OOP interface.

    - Instead of just having `trie-words($tr, <c>)` we should be also able to say `$tr.trie-words(<c>)`.
    
- [ ] TODO Implement `trie-prune` function.

- [X] DONE Implement Trie-based classification.

- [X] DONE Create trie from hash representation.

- [ ] TODO Investigate faster implementations.
 
  - [X] DONE Re-implement the Trie functionalities using hash representation (instead of a tree of Trie-node objects.)
    
     - See [AAp6].
  
  - [ ] TODO Make a C or C++ implementation and hook it up to Raku.  
  
- [X] DONE Program a trie-form visualization that is "wide", i.e. places the children nodes horizontally.
  
     - Using "Pretty::Table". 
     - Using the function `to-pretty-table` of "Data::Reshapers". (Also based on "Pretty::Table".) 

- [ ] TODO Document examples of doing Trie-based text mining or data-mining.

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

[JW1] Jonathan Worthington,
["The new MoarVM dispatch mechanism is here!"](https://6guts.wordpress.com/2021/09/29/the-new-moarvm-dispatch-mechanism-is-here/),
(2021),
[6guts at WordPress](https://6guts.wordpress.com).

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

[AAp7] Anton Antonov,
[UML::Translators Raku package](https://raku.land/zef:antononcube/UML::Translators),
(2022),
[GitHub/antononcube](https://github.com/antononcube).

### Videos

[AAv1] Anton Antonov,
["Prefix Trees with Frequencies for Data Analysis and Machine Learning"](https://www.youtube.com/watch?v=MdVp7t8xQbQ),
(2017),
Wolfram Technology Conference 2017,
[Wolfram channel at YouTube](https://www.youtube.com/channel/UCJekgf6k62CQHdENWf2NgAQ).

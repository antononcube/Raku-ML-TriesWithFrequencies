# Raku ML::TriesWithFrequencies

[![SparkyCI](http://sparrowhub.io:2222/project/gh-antononcube-Raku-ML-TriesWithFrequencies/badge)](http://sparrowhub.io:2222)
[![License: Artistic-2.0](https://img.shields.io/badge/License-Artistic%202.0-0298c3.svg)](https://opensource.org/licenses/Artistic-2.0)

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

-------

## Installation

Via zef-ecosystem:

```shell
zef install ML::TriesWithFrequencies
```

From GitHub:

```shell
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

Here is a "dot-pipeline" that combines the steps above: 

```perl6
<bar bark bars balm cert cell>.&trie-create-by-split
.node-probabilities
.shrink
.retrieve(<ba r>)        
.form
```
```
# r => 0.75
# ├─k => 0.3333333333333333
# └─s => 0.3333333333333333
```

**Remark:** In the pipeline above we retrieve with `<ba r>`, not with `<b a r>`, 
because the trie is already shrunk.


The package provides a fair amount of functions in order to facilitate ML applications. 
In support of that statement, here are the methods of `ML::TriesWithFrequencies::Trie`:

```perl6
ML::TriesWithFrequencies::Trie.^method_names
```
```
# (clone make merge insert create create-by-split node-probabilities leaf-probabilities leafQ position retrieve has-complete-match contains is-key shrink node-counts remove-by-threshold remove-by-pareto-fraction remove-by-regex select-by-threshold select-by-pareto-fraction select-by-regex root-to-leaf-paths words words-with-probabilities classify echo echo-function form trieRootLabel trieValueLabel getKey getValue getChildren setKey setValue setChildren toMapFormat hash WL toWLFormatRec XML toXMLFormatRec JSON toJSONFormatRec Str gist new key value children BUILDALL)
```

------

## Representation

Each trie is a tree of objects of the class `ML::TriesWithFrequencies::Trie`.
Such trees can be nicely represented as hash-maps. For example:

```perl6
my $tr = trie-shrink(trie-create-by-split(<core cort>));
say $tr.gist;
```
```
# {TRIEROOT => {TRIEVALUE => 2, cor => {TRIEVALUE => 2, e => {TRIEVALUE => 1}, t => {TRIEVALUE => 1}}}}
```

The function `trie-say` uses that Hash-representation:

```perl6
trie-say($tr)
```
```
# TRIEROOT => 2
# └─cor => 2
#   ├─e => 1
#   └─t => 1
```

### JSON

The JSON-representation follows the inherent object-tree
representation with `ML::TriesWithFrequencies::Trie`:

```perl6
say $tr.JSON;
```
```
# {"key":"TRIEROOT", "value":2, "children":[{"key":"cor", "value":2, "children":[{"key":"e", "value":1, "children":[]}, {"key":"t", "value":1, "children":[]}]}]}
```

### XML

The XML-representation follows (resembles) the Hash-representation 
(and output from `trie-say`):

```perl6
say $tr.XML;
```
```
# <TRIEROOT>
#  <TRIEVALUE>2</TRIEVALUE>
#  <cor>
#   <TRIEVALUE>2</TRIEVALUE>
#   <e>
#    <TRIEVALUE>1</TRIEVALUE>
#   </e>
#   <t>
#    <TRIEVALUE>1</TRIEVALUE>
#   </t>
#  </cor>
# </TRIEROOT>
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
```
# TRIEROOT => 2
# └─b => 2
#   └─e => 2
#     ├─l => 1
#     │ └─l => 1
#     └─s => 1
#       └─t => 1
```
Convert to XML:

```perl6
say $tr0.XML;
```
```
# <TRIEROOT>
#  <TRIEVALUE>2</TRIEVALUE>
#  <b>
#   <TRIEVALUE>2</TRIEVALUE>
#   <e>
#    <TRIEVALUE>2</TRIEVALUE>
#    <s>
#     <TRIEVALUE>1</TRIEVALUE>
#     <t>
#      <TRIEVALUE>1</TRIEVALUE>
#     </t>
#    </s>
#    <l>
#     <TRIEVALUE>1</TRIEVALUE>
#     <l>
#      <TRIEVALUE>1</TRIEVALUE>
#     </l>
#    </l>
#   </e>
#  </b>
# </TRIEROOT>
```

Search for `<b e l>`:

```perl6
say XML::XPath.new(xml=>$tr0.XML).find('//b/e/l');
```
```
# <l>
#     <TRIEVALUE>1</TRIEVALUE> 
#     <l>
#      <TRIEVALUE>1</TRIEVALUE> 
#     </l> 
#    </l>
```

### WL

The Hash-representation is used in the Mathematica package [AAp2].
Hence, such WL format is provided by the Raku package:

```perl6
say $tr.WL;
```
```
# <|$TrieRoot -> <|$TrieValue -> 2, "cor" -> <|$TrieValue -> 2, "e" -> <|$TrieValue -> 1|>, "t" -> <|$TrieValue -> 1|>|>|>|>
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
```
# TRIEROOT => 1
# ├─b => 0.625
# │ ├─a => 0.6
# │ │ ├─r => 0.6666666666666666
# │ │ │ └─man => 0.5
# │ │ └─sk => 0.3333333333333333
# │ └─ell => 0.4
# │   └─y => 0.5
# └─ca => 0.375
#   ├─ll => 0.3333333333333333
#   ├─r => 0.3333333333333333
#   └─st => 0.3333333333333333
```

The package also supports "dot pipelining" through chaining of methods:

```perl6
@words2.&trie-create-by-split
        .merge(@words3.&trie-create-by-split)
        .node-probabilities
        .shrink
        .form
```
```
# TRIEROOT => 1
# ├─b => 0.625
# │ ├─a => 0.6
# │ │ ├─r => 0.6666666666666666
# │ │ │ └─man => 0.5
# │ │ └─sk => 0.3333333333333333
# │ └─ell => 0.4
# │   └─y => 0.5
# └─ca => 0.375
#   ├─ll => 0.3333333333333333
#   ├─r => 0.3333333333333333
#   └─st => 0.3333333333333333
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

![](./resources/class-diagram.png)


The
[PlantUML spec](./resources/class-diagram.puml)
and
[diagram](./resources/class-diagram.png)
were obtained with the CLI script `to-uml-spec` of the package "UML::Translators", [AAp7].

Here we get the [PlantUML spec](./resources/class-diagram.puml):

```shell
to-uml-spec ML::TriesWithFrequencies > ./resources/class-diagram.puml
```

Here get the [diagram](./resources/class-diagram.png):

```shell
to-uml-spec ML::TriesWithFrequencies | java -jar ~/PlantUML/plantuml-1.2022.5.jar -pipe > ./resources/class-diagram.png
```

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

In order to get chains of Object Oriented Programming (OOP) methods application that 
are typical in Raku programming the package versions after version 0.6.0 have trie 
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

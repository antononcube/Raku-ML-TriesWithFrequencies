use ML::TriesWithFrequencies::Trie;
use ML::TriesWithFrequencies::ParetoBasedRemover;
use ML::TriesWithFrequencies::PathsGatherer;
use ML::TriesWithFrequencies::RegexBasedRemover;
use ML::TriesWithFrequencies::ThresholdBasedRemover;

unit module ML::TriesWithFrequencies;

constant $TrieRoot = ML::TriesWithFrequencies::Trie.trieRootLabel;
constant $TrieValue = ML::TriesWithFrequencies::Trie.trieValueLabel;

##=======================================================
## Core functions -- creation, merging, insertion, node frequencies
##=======================================================

#| @description Makes a base trie from a list
#| @param chars a list of objects
#| @param val value (e.g. frequency) to be assigned
#| @param bottomVal the bottom value
sub trie-make(@chars,
              Num :$value = 1e0,
              Num :$bottomValue = 1e0,
              Bool :$verify-input = True
        --> ML::TriesWithFrequencies::Trie) is export {

    return ML::TriesWithFrequencies::Trie.make(@chars, :$value, :$bottomValue, :$verify-input);
}

#--------------------------------------------------------
#| Merge tries.
sub trie-merge(ML::TriesWithFrequencies::Trie $tr1,
               ML::TriesWithFrequencies::Trie $tr2,
               Bool :$merge-clones = True
        --> ML::TriesWithFrequencies::Trie) is export {

    return ML::TriesWithFrequencies::Trie.merge($tr1, $tr2);
}

#--------------------------------------------------------
#proto trie-insert(ML::TriesWithFrequencies::Trie $tr, |) is export {*};

#|Inserts a "word" (a list of strings) into a trie with a given associated value.
sub trie-insert(ML::TriesWithFrequencies::Trie $tr,
                @word,
                Num :$value = 1e0,
                Num :$bottomValue = 1e0,
                Bool :$verify-input = True,
                Bool :$merge-clones = True
        --> ML::TriesWithFrequencies::Trie) is export {

    return $tr.insert(@word, :$value, :$bottomValue, :$verify-input, :$merge-clones);
}

#--------------------------------------------------------
#| Creates a trie from a given list of list of strings. (Recursively.)
sub trie-create(@words,
                UInt :$bisection-threshold = 15,
                Bool :$verify-input = True
        --> ML::TriesWithFrequencies::Trie) is export {

  return ML::TriesWithFrequencies::Trie.create(@words, :$bisection-threshold, :$verify-input);
}

#--------------------------------------------------------
#| Creates a trie by splitting each of the strings in the given list of strings.
#| C<:$splitter, :$skip-empty, :$v> are passed to C<split>.
#| C<$bisection-threshold> : the threshold after which to stop binary recursive calls.
proto trie-create-by-split($words, |) is export {*}

multi trie-create-by-split(Str $word, *%args) {
    trie-create-by-split([$word], |%args)
}

multi trie-create-by-split(@words,
                           :$splitter = '',
                           :$skip-empty = True,
                           :$v = False,
                           UInt :$bisection-threshold = 15
        --> ML::TriesWithFrequencies::Trie) {
    return ML::TriesWithFrequencies::Trie.create-by-split(@words, :$splitter, :$skip-empty, :$v, :$bisection-threshold);
}

#--------------------------------------------------------
#| Converts the counts (frequencies) at the nodes into node probabilities.
#| @param tr a trie object
sub trie-node-probabilities(ML::TriesWithFrequencies::Trie $tr) is export {
    return $tr.node-probabilities;
}

##=======================================================
## Retrieval functions
##=======================================================

#--------------------------------------------------------
#| @description Test is a trie object a leaf.
sub trie-leafQ(ML::TriesWithFrequencies::Trie $tr --> Bool) {
    return not ($tr.children.defined and $tr.children)
}

#--------------------------------------------------------
#| @description Find the position of a given word (or part of it) in the trie.
#| @param tr a trie object
#| @param word a list of strings
sub trie-position(ML::TriesWithFrequencies::Trie $tr,
                  @word
        --> Positional) is export {

    if not so @word { return Nil; }

    if not so $tr.children { return Nil; }

    if not @word.all ~~ Str {
        die "The second argument is expected to be a positional of strings."
    }

    if not $tr.children{@word[0]}:exists {
        return Nil;
    }

    my @res;
    @res.append(@word[0]);
    my $rpos = trie-position($tr.children{@word[0]}, @word[1 .. (@word.elems - 1)]);

    if not ($rpos.defined and $rpos) {
        return @res;
    } else {
        @res.append(|$rpos);
        return @res;
    }

}

#--------------------------------------------------------
#| @description Retrieval of a sub-trie corresponding to a "word".
#| @param tr a trie object
proto trie-retrieve(ML::TriesWithFrequencies::Trie $tr, |
        --> ML::TriesWithFrequencies::Trie) is export {*}

#| @description Retrieval of a sub-trie corresponding to a "word".
#| @param $tr a trie object
#| @param $word a string
multi trie-retrieve(ML::TriesWithFrequencies::Trie $tr, $word
        --> ML::TriesWithFrequencies::Trie) {
    trie-retrieve($tr, [$word,])
}

#| @description Retrieval of a sub-trie corresponding to a "word".
#| @param tr a trie object
#| @param word a list of strings
multi trie-retrieve(ML::TriesWithFrequencies::Trie $tr, @word
        --> ML::TriesWithFrequencies::Trie) {

    if not so @word { return $tr; }

    if not so $tr.children { return $tr; }

    if not @word.all ~~ Str {
        die "The second argument is expected to be a positional of strings."
    }

    if not $tr.children{@word[0]}:exists {
        return $tr;
    } else {
        return trie-retrieve($tr.children{@word[0]}, @word[1 .. (@word.elems - 1)]);
    }
}

#--------------------------------------------------------
#| @description For a given trie finds if the retrievable part of a word is complete match.
#| @param tr a trie object
proto trie-has-complete-match(ML::TriesWithFrequencies::Trie $tr, | --> Bool) is export {*}

#| @description For a given trie finds if the retrievable part of a word is complete match.
#| @param tr a trie object
#| @param word a list of strings
multi trie-has-complete-match(ML::TriesWithFrequencies::Trie $tr, $word --> Bool) {
    return $tr.has-complete-match([$word,]);
}

#| @description For a given trie finds if the retrievable part of a word is complete match.
#| @param tr a trie object
#| @param word a list of strings
#| @details Despite the name this function works on the part of the word that can be found in the trie.
multi trie-has-complete-match(ML::TriesWithFrequencies::Trie $tr, @word --> Bool) {
    return $tr.has-complete-match(@word);
}

#--------------------------------------------------------
#| @description Does the trie object tr contains a word.
#| @param tr a trie object
proto trie-contains(ML::TriesWithFrequencies::Trie $tr, | --> Bool) is export {*}

#| @description Does the trie object tr contains a word.
#| @param tr a trie object
#| @param word a word to be checked
multi trie-contains(ML::TriesWithFrequencies::Trie $tr, $word --> Bool) {
    return $tr.contains([$word,]);
}

#| @description Does the trie object tr contains a word.
#| @param tr a trie object
#| @param word a word to be checked
multi trie-contains(ML::TriesWithFrequencies::Trie $tr, @word --> Bool) is export {
    return $tr.contains(@word);
}

#--------------------------------------------------------
#| @description Does the trie object tr has a word as key.
#| @param tr a trie object
proto trie-is-key(ML::TriesWithFrequencies::Trie $tr, | --> Bool) is export {*}

#| @description Does the trie object tr has a word as key.
#| @param tr a trie object
#| @param word a word to be checked
multi trie-is-key(
#| Trie object
        ML::TriesWithFrequencies::Trie $tr,

#| A string "word" to test as a key
        $word

        --> Bool) {
    return $tr.is-key([$word,]);
}

#| @description Does the trie object tr has a word as key.
#| @param tr a trie object
#| @param word a word to be checked
multi trie-is-key(
#| Trie object
        ML::TriesWithFrequencies::Trie $tr,

#| A positional "word" to test as a key
        @word

        --> Bool) is export {
    return $tr.is-key(@word);
}

##=======================================================
## Shrinking functions
##=======================================================
#| @description Shrinks a trie by finding prefixes.
#| @param tr A trie object.
#| @param sep A sep to be used when strings are joined.
#| @param threshold Above what threshold to do the shrinking. If negative automatic shrinking test is applied.
sub trie-shrink(
#| Trie object
        Trie $tr,

#| Separator string to be used when strings are joined.
        Str :$sep = '',

#| Above what threshold to do the shrinking. If negative automatic shrinking test is applied.
        num :$threshold = -1e0,

#| Should only internal nodes be shrunk or not?
        Bool :$internal-only = False

        --> ML::TriesWithFrequencies::Trie) is export {
    return $tr.shrink(:$sep, :$threshold, :$internal-only);
}


##=======================================================
## Statistics functions
##=======================================================

#| @description Finding the counts of nodes in a trie.
#| @param tr trie object
#| @return Returns the values for "total", "internal", "leaves".
sub trie-node-counts(
#| Trie object
        ML::TriesWithFrequencies::Trie $tr

        --> Hash) is export {
    return $tr.node-counts;
}

##=======================================================
## Removal functions
##=======================================================

#--------------------------------------------------------
#| Remove nodes by threshold.
sub trie-remove-by-threshold (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Threshold
        Numeric $threshold,

#| Should nodes with values below the threshold be removed or not?
        Bool :$below-threshold = True,

#| Name of the aggregation node with value that equals the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {

    return $tr.remove-by-threshold($threshold, :$below-threshold, :$postfix);
}

#--------------------------------------------------------
#| Remove nodes by Pareto fraction.
sub trie-remove-by-pareto-fraction (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Pareto fraction
        Numeric $fraction,

#| Should bottom nodes be removed or not?
        Bool :$bottom = True,

#| Name of the aggregation node with value that equals the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {

   return $tr.remove-by-pareto-fraction($fraction, :$bottom, :$postfix);
}

#--------------------------------------------------------
#| Remove nodes by regex.
sub trie-remove-by-regex (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Regex
        $key-pattern,

#| Should the regex be inverted or not?
        Bool :$invert = False,

#| Name of the aggregation node with value that equals the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {
    return $tr.remove-by-regex($key-pattern, :$invert, :$postfix);
}


##=======================================================
## Selection functions
##=======================================================

#--------------------------------------------------------
#| Select nodes by threshold.
sub trie-select-by-threshold (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Threshold
        Numeric $threshold,

#| Should nodes with values above the threshold be selected or not?
        Bool :$above-threshold = True,

#| Name of the aggregation node with value that equals the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {
    return $tr.remove-by-threshold($threshold, below-threshold => $above-threshold, :$postfix);
}

#--------------------------------------------------------
#| Select nodes by Pareto fraction.
sub trie-select-by-pareto-fraction (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Pareto fraction
        Numeric $fraction,

#| Should top nodes be selected or not?
        Bool :$top = True,

#| Name of the aggregation node with value that equals the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {
    return $tr.remove-by-pareto-fraction($fraction, bottom => $$top, :$postfix);
}

#--------------------------------------------------------
#| Select nodes by regex.
sub trie-select-by-regex (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Regex
        $key-pattern,

#| Should the regex be inverted or not?
        Bool :$invert = False,

#| Name of the aggregation node with value that equal the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {
    return $tr.remove-by-regex($key-pattern, invert => !$invert, :$postfix);
}


##=======================================================
## Classify functions
##=======================================================

#--------------------------------------------------------
#| Classify record(s).
#| C<prop> takes the values C<[Whatever, "Decision", "Probabilities" 'Values"]>, or C<Probability => <some-label>>.
#| "Probs" and "Prob" can be used instead of "Probabilities" and "Probability" respectively;
#| "Value" can be used instead of "Values".
sub trie-classify (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Record(s)
        $records,

#| Property
        Str :$prop
                   ) is export {
    return $tr.classify($records, :$prop);
}


##=======================================================
## Path functions
##=======================================================
#| @description Finds the paths from the root of a trie to the leaves.
#| @param tr a trie object
sub trie-root-to-leaf-paths( ML::TriesWithFrequencies::Trie $tr, :$ulp = Whatever --> Positional) is export {
    return $tr.root-to-leaf-paths(:$ulp);
}

##-------------------------------------------------------
proto trie-words(ML::TriesWithFrequencies::Trie $tr, | --> Positional) is export {*};

#| @description Finds all words in the trie tr that start with the word searchWord.
#| @param tr a trie object
#| @param sw a list of strings
#| @param sep is a separator
multi trie-words(ML::TriesWithFrequencies::Trie $tr, $sw, :$sep = Whatever --> Positional) {
    return $tr.words($sw, :$sep);
}

#| @description Finds all words in the trie tr that start with the word searchWord.
#| @param tr a trie object
#| @param sep is a separator
multi trie-words(ML::TriesWithFrequencies::Trie $tr, :$sep = Whatever --> Positional) {
    return $tr.words(:$sep);
}

##-------------------------------------------------------
#| @description Finds all words in the trie tr that start with the word searchWord.
#| @param tr a trie object
#| @param sep is a separator
sub trie-words-with-probabilities(ML::TriesWithFrequencies::Trie $tr, :$sep = Whatever) is export {
    return $tr.words-with-probabilities(:$sep);
}

##=======================================================
## Visualization functions
##=======================================================

#--------------------------------------------------------
#| Make the visualization trie form
sub trie-form(
#| Trie object
        ML::TriesWithFrequencies::Trie $tr,

#| A string that is the left boundary marker of a node
        Str :$lb = '',

#| A string that separates the key and value of a node
        Str :$sep = ' => ',

#| A string that is the right boundary marker of a node
        Str :$rb = '',

#| Should key-value nodes be used not?
        Bool :$key-value-nodes = True) is export {
    return $tr.form(:$lb, :$sep, :$rb, :$key-value-nodes);
}

#--------------------------------------------------------
#| Visualize trie form
sub trie-say(
#| Trie object
        ML::TriesWithFrequencies::Trie $tr,

#| A string that is the left boundary marker of a node
        Str :$lb = '',

#| A string that separates the key and value of a node
        Str :$sep = ' => ',

#| A string that is the right boundary marker of a node
        Str :$rb = '',

#| Should key-value nodes be used not?
        Bool :$key-value-nodes = True) is export {
    say trie-form($tr, :$lb, :$sep, :$rb, :$key-value-nodes);
}
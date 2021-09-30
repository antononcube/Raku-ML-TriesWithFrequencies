use ML::TriesWithFrequencies::Trie;
use ML::TriesWithFrequencies::ParetoBasedRemover;
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

    if $verify-input and not @chars.all ~~ Str {
        die "The first argument is expected to be a positional of strings."
    }

    if not so @chars {
        return Nil;
    }

    # First node
    my ML::TriesWithFrequencies::Trie $res = ML::TriesWithFrequencies::Trie.new(key => @chars[*- 1], value => $bottomValue);

    # Is this faster: @chars.head(@chars.elems-1).reverse;
    for @chars[^(*- 1)].reverse -> $c {
        my %children = $res.key => $res;
        $res = ML::TriesWithFrequencies::Trie.new(key => $c, :$value, :%children );
    }

    my ML::TriesWithFrequencies::Trie $res2 = ML::TriesWithFrequencies::Trie.new(key => $TrieRoot, :$value);
    $res2.children.push: ($res.key => $res);

    return $res2;
}

#--------------------------------------------------------
#| Merge tries.
sub trie-merge(ML::TriesWithFrequencies::Trie $tr1,
               ML::TriesWithFrequencies::Trie $tr2,
               Bool :$merge-clones = True
        --> ML::TriesWithFrequencies::Trie) is export {

    my ML::TriesWithFrequencies::Trie $res = ML::TriesWithFrequencies::Trie.new;

    if not so $tr1 {

        return $tr2;

    } elsif not so $tr2 {

        return $tr1;

    } elsif $tr1.key ne $tr2.key {

        return trie-merge(
                ML::TriesWithFrequencies::Trie.new(key => $TrieRoot, value => $tr1.value, children => %($TrieRoot => $tr1.children)),
                ML::TriesWithFrequencies::Trie.new(key => $TrieRoot, value => $tr2.value, children => %($TrieRoot => $tr2.children)),
                :$merge-clones);

    } elsif $tr1.key eq $tr2.key {

        if not so $tr1.children {

            return $merge-clones ?? $tr2.clone.setValue($tr1.value + $tr2.value) !! $tr2.setValue($tr1.value + $tr2.value);

        } elsif not so $tr2.children {

            return $merge-clones ?? $tr1.clone.setValue($tr1.value + $tr2.value) !! $tr1.setValue($tr1.value + $tr2.value);

        }

        $res.setKey($tr1.key);
        $res.setValue($tr1.value + $tr2.value);

        # Here we merge using the keys of the smaller hash of children.
        # Hence the two almost identical codes.
        if $tr1.children.elems < $tr2.children.elems {

            $res.setChildren( $tr2.children );

            for $tr1.children.keys -> $key1 {

                if $res.children{$key1}:!exists {
                    $res.children.push: $tr1.children{$key1}:p;
                } else {
                    $res.children{$key1} = trie-merge($tr1.children{$key1}, $res.children{$key1}, :$merge-clones);
                }
            }

        } else {

            $res.setChildren( $tr1.children );

            for $tr2.children.keys -> $key2 {

                if $res.children{$key2}:!exists {
                    $res.children.push: $tr2.children{$key2}:p;
                } else {
                    $res.children{$key2} = trie-merge($tr2.children{$key2}, $res.children{$key2}, :$merge-clones);
                }
            }
        }

        return $res;
    }

    return Nil;
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

    if $verify-input and not @word.all ~~ Str {
        die "The second argument is expected to be a positional of strings."
    }

   trie-merge($tr, trie-make(@word, :$value, :$bottomValue, :!verify-input), :$merge-clones)
}

#--------------------------------------------------------

#| Creates a trie from a given list of list of strings. (Non-recursively.)
sub trie-create1(@words,
                 Bool :$verify-input = True
        --> ML::TriesWithFrequencies::Trie) {

    if $verify-input and not @words.all ~~ Positional {
        die "The first argument is expected to be a positional of positionals of strings."
    }

    if not so @words {
        return Nil;
    }

    my ML::TriesWithFrequencies::Trie $res = trie-make(@words[0]);

    for @words[1 .. (@words.elems - 1)] -> @w {
        $res = trie-insert($res, @w, :$verify-input, :!merge-clones);
    }

    return $res;
}

#--------------------------------------------------------
#| Creates a trie from a given list of list of strings. (Recursively.)
sub trie-create(@words,
                UInt :$bisection-threshold = 15,
                Bool :$verify-input = True
        --> ML::TriesWithFrequencies::Trie) is export {

    if not so @words { return Nil; }

    if $verify-input and not @words.all ~~ Positional {
        die "The first argument is expected to be a positional of positionals of strings."
    }

    if @words.elems <= $bisection-threshold {
        return trie-create1(@words, :!verify-input);
    }

    return trie-merge(
            trie-create(@words[^ceiling(@words.elems / 2)], :$bisection-threshold, :!verify-input),
            trie-create(@words[ceiling(@words.elems / 2) .. (@words.elems - 1)], :$bisection-threshold, :!verify-input));
}

#--------------------------------------------------------
#| Creates a trie by splitting each of the strings in the given list of strings.
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

    if not so @words { return Nil }

    if not @words.all ~~ Str {
        die "The first argument is expected to be a positional of strings."
    }

    trie-create(@words.map({ [$_.split($splitter, :$skip-empty, :$v)] }), :$bisection-threshold);
}

#--------------------------------------------------------
#| Converts the counts (frequencies) at the nodes into node probabilities.
#| @param tr a trie object
sub trie-node-probabilities(ML::TriesWithFrequencies::Trie $tr) is export {
    my ML::TriesWithFrequencies::Trie $res = nodeProbabilitiesRec($tr);
    $res.setValue(1e0);
    return $res;
}

#| @description Recursive step function for converting node frequencies into node probabilities.
#| @param tr a trie object
sub nodeProbabilitiesRec(ML::TriesWithFrequencies::Trie $tr) {
    my num $chSum = 0e0;

    if !$tr.children {
        return ML::TriesWithFrequencies::Trie.new(key => $tr.key, value => $tr.value);
    }

    if ($tr.value == 0) {
        ## This is a strange case -- that generally should not happen.
        $chSum = 0e0;
        for $tr.children.values -> $ch {
            $chSum += $ch.getValue();
        }
    } else {
        $chSum = $tr.value;
    }

    my %resChildren = %();

    for $tr.children.kv -> $k, $v {
        my ML::TriesWithFrequencies::Trie $chNode = nodeProbabilitiesRec($v);
        $chNode.setValue($chNode.value / $chSum);
        %resChildren.push: ($v.key => $chNode);
    }

    return ML::TriesWithFrequencies::Trie.new(key => $tr.key, value => $tr.value, children => %resChildren);
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
#| @param word a list of strings
sub trie-retrieve(ML::TriesWithFrequencies::Trie $tr,
                  @word
        --> ML::TriesWithFrequencies::Trie) is export {

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
#| @param word a list of strings
#| @details Despite the name this function works on the part of the word that can be found in the trie.
sub trie-has-complete-match(ML::TriesWithFrequencies::Trie $tr,
                            @word
        --> Bool) is export {

    if not so $tr { return False }

    if not so @word { return False }

    if not @word.all ~~ Str {
        die "The second argument is expected to be a positional of strings."
    }

    my ML::TriesWithFrequencies::Trie $subTr = trie-retrieve($tr, @word);

    if not so $subTr.children {
        return True;
    } else {
        my num $chValue = 0e0;

        for $subTr.children.values -> $ch {
            $chValue += $ch.value
        }

        return $chValue < $subTr.value
    }
}

#--------------------------------------------------------
#| @description Does the trie object tr contains a word.
#| @param tr a trie object
#| @param word a word to be checked
sub trie-contains(ML::TriesWithFrequencies::Trie $tr,
                  @word
        --> Bool) is export {

    if not so @word { return Nil }

    if not @word.all ~~ Str {
        die "The second argument is expected to be a positional of strings."
    }

    my $pos = trie-position($tr, @word);

    if not so $pos or $pos.elems < @word.elems {
        return False;
    } else {
        return trie-has-complete-match($tr, $pos);
    }
}

#--------------------------------------------------------
#| @description Does the trie object tr has a word as key.
#| @param tr a trie object
#| @param word a word to be checked
sub trie-is-key(ML::TriesWithFrequencies::Trie $tr,
                @word
        --> Bool) is export {

    if not so @word { return Nil }

    if not @word.all ~~ Str {
        die "The second argument is expected to be a positional of strings."
    }

    my $pos = trie-position($tr, @word);

    if not so $pos or $pos.elems < @word.elems {
        return False;
    } else {
        return True;
    }
}

##=======================================================
## Shrinking functions
##=======================================================
#| @description Shrinks a trie by finding prefixes.
#| @param tr A trie object.
#| @param sep A sep to be used when strings are joined.
#| @param threshold Above what threshold to do the shrinking. If negative automatic shrinking test is applied.
sub trie-shrink(Trie $tr, str :$sep = '', num :$threshold = -1e0, Bool :$internal-only = False) is export {
    return shrinkRec($tr, $sep, $threshold, $internal-only, 0);
}

#| @description Shrinking recursive function.
#| @param tr a trie object
#| @param sep a sep for the concatenation of the node keys
#| @param threshold if negative automatic shrinking test is applied
#| @param n recursion level
sub shrinkRec(ML::TriesWithFrequencies::Trie $tr,
              str $sep,
              num $threshold,
              Bool $internalOnly,
              Int $n
        --> ML::TriesWithFrequencies::Trie) {

    my ML::TriesWithFrequencies::Trie $trRes = ML::TriesWithFrequencies::Trie.new();
    my Bool $rootQ = ($n == 0 and $tr.key eq $TrieRoot);

    if !so $tr.children {

        return $tr;

    } elsif (not $rootQ and $tr.children.elems == 1) {

        my @arr = $tr.children.values;
        my Bool $shrinkQ = False;

        if $threshold < 0 and $tr.value >= 1e0 and @arr[0].value >= 1e0 {
            $shrinkQ = $tr.value eqv @arr[0].value;
        } elsif $threshold < 0 {
            $shrinkQ = @arr[0].value == 1e0;
        } else {
            $shrinkQ = @arr[0].value >= $threshold;
        }

        if $shrinkQ and (!$internalOnly or $internalOnly and not trie-leafQ(@arr[0])) {
            ## Only one child and the current node does not make a complete match:
            ## proceed with recursion and join with result.

            my ML::TriesWithFrequencies::Trie $chTr = shrinkRec(@arr[0], $sep, $threshold, $internalOnly, $n + 1);

            $trRes.setKey($tr.key ~ $sep ~ $chTr.key);
            $trRes.setValue($tr.value);

            with $chTr.children {
                $trRes.setChildren($chTr.children);
            }

        } else {
            ## Only one child but the current node makes a complete match.

            my ML::TriesWithFrequencies::Trie $chTr = shrinkRec(@arr[0], $sep, $threshold, $internalOnly, $n + 1);

            $trRes.setKey($tr.key);
            $trRes.setValue($tr.value);
            $trRes.children().push: ($chTr.key => $chTr);
        }

        return $trRes;

    } else {
        ## No shrinking at this node. Proceed with recursion.
        my %recChildren;

        for $tr.children.values -> $chTr {
            my ML::TriesWithFrequencies::Trie $nTr = shrinkRec($chTr, $sep, $threshold, $internalOnly, $n + 1);
            %recChildren.push: ($nTr.key => $nTr);
        }

        $trRes.setKey($tr.key);
        $trRes.setValue($tr.value);
        $trRes.setChildren(%recChildren);

        return $trRes;
    }
}

##=======================================================
## Statistics functions
##=======================================================

#| @description Finding the counts of nodes in a trie.
#| @param tr trie object
#| @return Returns the values for "total", "internal", "leaves".
sub trie-node-counts(ML::TriesWithFrequencies::Trie $tr) is export {
        ## The result would like { "total"->23, "internal"->12, "leaves"->11 }.

        my $res = nodeCountsRec($tr, 0, 0);

        return { Total => $res.key + $res.value, Internal => $res.key, Leaves => $res.value }
}

#| @description Finding the counts of internal nodes and leaf nodes in a trie.
#| @param tr trie object
#| @param nInternal number of internal nodes
#| @param nLeaves number of leaf nodes
#| @return A pair object with the new values of nInternal and nLeaves.
sub nodeCountsRec(ML::TriesWithFrequencies::Trie $tr, UInt $nInternal, UInt $nLeaves) {
    if not so $tr.children {
        return ($nInternal => $nLeaves + 1);
    } else {
        my $res = $nInternal => $nLeaves;

        for $tr.children.values -> $chTr {
            $res = nodeCountsRec($chTr, $res.key, $res.value);
        }

        return ($res.key + 1) => $res.value;
    }
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

        #| Name of the aggregation node with value that equal the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {

    my $robj = ML::TriesWithFrequencies::ThresholdBasedRemover.new( threshold => $threshold.Num, :$below-threshold, :$postfix );

    $robj.trie-threshold-remove($tr)
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

#| Name of the aggregation node with value that equal the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {

    my $robj = ML::TriesWithFrequencies::ParetoBasedRemover.new( pareto-fraction => $fraction.Num, remove-bottom => $bottom, :$postfix );

    $robj.trie-pareto-remove($tr)
}

#--------------------------------------------------------
#| Remove nodes by Pareto fraction.
sub trie-remove-by-regex (
#| Trie
        ML::TriesWithFrequencies::Trie $tr,

#| Pareto fraction
        $key-pattern,

#| Should the regex be inverted or not?
        Bool :$invert = False,

#| Name of the aggregation node with value that equal the removed sum.
        Str :$postfix = ''

        --> ML::TriesWithFrequencies::Trie) is export {

    my $robj = ML::TriesWithFrequencies::RegexBasedRemover.new( :$key-pattern, :$invert, :$postfix );

    $robj.trie-regex-remove($tr)
}

##=======================================================
## Removal functions
##=======================================================

#--------------------------------------------------------
#| Visualize
sub trie-say(ML::TriesWithFrequencies::Trie $tr,
             Str :$lb = '',
             Str :$sep = ' => ',
             Str :$rb = '',
             Bool :$key-value-nodes = True) is export {
    .say for visualize-tree( $tr.toMapFormat.first, *.key, *.value.List, :$lb, :$sep, :$rb, :$key-value-nodes);
}

## Adapted from here:
##   https://titanwolf.org/Network/Articles/Article?AID=34018e5b-c0d5-4351-85b6-d72bd049c8c0
sub visualize-tree($tree, &label, &children,
                   :$indent = '',
                   :@mid = ('├─', '│ '),
                   :@end = ('└─', '  '),
                   Str :$lb = '',
                   Str :$sep = ' => ',
                   Str :$rb = '',
                   Bool :$key-value-nodes = True
                   ) {
    sub visit($node, *@pre) {
        my $suffix = '';
        if $key-value-nodes and $node.value.isa(Hash) and $node.value{$TrieValue}:exists {
            $suffix = $sep ~ $node.value{$TrieValue}
        }
        gather {
            if $node.&label ~~ $TrieValue {
                if not $key-value-nodes {
                    take @pre[0] ~ $node.value
                }
            } else {
                take @pre[0] ~ $lb ~ $node.&label ~ $suffix ~ $rb;
                my @children = sort $node.&children.grep({ $_.key ne $TrieValue });
                my $end = @children.end;
                for @children.kv -> $_, $child {
                    when $end { take visit($child, (@pre[1] X~ @end)) }
                    default { take visit($child, (@pre[1] X~ @mid)) }
                }
            }
        }
    }

    flat visit($tree, $indent xx 2);
}
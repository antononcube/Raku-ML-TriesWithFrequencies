use ML::TriesWithFrequencies::Trie;

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
    my ML::TriesWithFrequencies::Trie $res = ML::TriesWithFrequencies::Trie.new(key => @chars[*- 1],
            value => $bottomValue);

    # Is this faster: @chars.head(@chars.elems-1).reverse;
    for @chars[^(*- 1)].reverse -> $c {
        my %children = $res.getKey() => $res;
        $res = ML::TriesWithFrequencies::Trie.new(key => $c, :$value, :%children);
    }

    my ML::TriesWithFrequencies::Trie $res2 = ML::TriesWithFrequencies::Trie.new(key => $TrieRoot, :$value);
    $res2.children.push: ($res.getKey() => $res);

    return $res2;
}

#--------------------------------------------------------
#| Merge tries.
sub trie-merge(ML::TriesWithFrequencies::Trie $tr1,
               ML::TriesWithFrequencies::Trie $tr2
        --> ML::TriesWithFrequencies::Trie) is export {

    my ML::TriesWithFrequencies::Trie $res = ML::TriesWithFrequencies::Trie.new;

    if not ($tr1.defined and $tr1) {

        return $tr2;

    } elsif not ($tr2.defined and $tr2) {

        return $tr1;

    } elsif $tr1.key ne $tr2.key {

        return trie-merge(
                ML::TriesWithFrequencies::Trie.new(key => $TrieRoot, value => $tr1.value, children => %($TrieRoot => $tr1.children)),
                ML::TriesWithFrequencies::Trie.new(key => $TrieRoot, value => $tr2.value, children => %($TrieRoot => $tr2.children)));

    } elsif $tr1.key eq $tr2.key {

        if not ($tr1.children.defined and $tr1.children) {

            $tr2.setValue($tr1.value + $tr2.value);
            return $tr2;

        } elsif not ($tr2.children.defined and $tr2.children) {

            $tr1.setValue($tr1.value + $tr2.value);
            return $tr1;

        }

        $res.setKey($tr1.key);
        $res.setValue($tr1.value + $tr2.value);

        for $tr1.children.pairs -> $elem1 {

            if not $tr2.children{$elem1.key}:exists {
                $res.children.push: ($elem1.key => $elem1.value);
            } else {
                $res.children.push: ($elem1.key => trie-merge($elem1.value, $tr2.children{$elem1.key}));
            }
        }

        for $tr2.children.pairs -> $elem2 {

            if not $tr1.children{$elem2.key}:exists {
                $res.children.push: ($elem2.key => $elem2.value);
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
                Bool :$verify-input = True
        --> ML::TriesWithFrequencies::Trie) is export {

    if not @word.all ~~ Str {
        die "The second argument is expected to be a positional of strings."
    }

   trie-merge($tr, trie-make(@word, :$value, :$bottomValue, :!verify-input))
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
        $res = trie-insert($res, @w, :$verify-input);
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

    trie-create(@words.map({ [$_.split($splitter, :skip-empty, :v)] }), :$bisection-threshold);
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
#| @param delimiter A delimiter to be used when strings are joined.
#| @param threshold Above what threshold to do the shrinking. If negative automatic shrinking test is applied.
sub trie-shrink(Trie $tr, str :$delimiter = '', num :$threshold = -1e0, Bool :$internal-only = False) is export {
    return shrinkRec($tr, $delimiter, $threshold, $internal-only, 0);
}

#| @description Shrinking recursive function.
#| @param tr a trie object
#| @param delimiter a delimiter for the concatenation of the node keys
#| @param threshold if negative automatic shrinking test is applied
#| @param n recursion level
sub shrinkRec(ML::TriesWithFrequencies::Trie $tr,
              str $delimiter,
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

            my ML::TriesWithFrequencies::Trie $chTr = shrinkRec(@arr[0], $delimiter, $threshold, $internalOnly, $n + 1);

            $trRes.setKey($tr.key ~ $delimiter ~ $chTr.key);
            $trRes.setValue($tr.value);

            with $chTr.children {
                $trRes.setChildren($chTr.children);
            }

        } else {
            ## Only one child but the current node makes a complete match.

            my ML::TriesWithFrequencies::Trie $chTr = shrinkRec(@arr[0], $delimiter, $threshold, $internalOnly, $n + 1);

            $trRes.setKey($tr.key);
            $trRes.setValue($tr.value);
            $trRes.children().push: ($chTr.key => $chTr);
        }

        return $trRes;

    } else {
        ## No shrinking at this node. Proceed with recursion.
        my %recChildren;

        for $tr.children.values -> $chTr {
            my ML::TriesWithFrequencies::Trie $nTr = shrinkRec($chTr, $delimiter, $threshold, $internalOnly, $n + 1);
            %recChildren.push: ($nTr.key => $nTr);
        }

        $trRes.setKey($tr.key);
        $trRes.setValue($tr.value);
        $trRes.setChildren(%recChildren);

        return $trRes;
    }
}

#--------------------------------------------------------
#| Visualize
sub trie-form(ML::TriesWithFrequencies::Trie $tr) is export {
    .say for visualize-tree $tr.toMapFormat{$TrieRoot}:p, *.key, *.value.List;
}

## Adapted from here:
##   https://titanwolf.org/Network/Articles/Article?AID=34018e5b-c0d5-4351-85b6-d72bd049c8c0
sub visualize-tree($tree, &label, &children,
                   :$indent = '',
                   :@mid = ('├─', '│ '),
                   :@end = ('└─', '  '),
                   ) {
    sub visit($node, *@pre) {
        gather {
            if $node.&label ~~ $TrieValue {
                take @pre[0] ~ $node.value
            }
            else {
                take @pre[0] ~ $node.&label;
                my @children = sort $node.&children;
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
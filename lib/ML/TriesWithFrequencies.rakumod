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
sub trie-make(@chars where $_.all ~~ Str,
              Numeric $val = 1.0,
              Numeric $bottomVal? is copy
        --> ML::TriesWithFrequencies::Trie) is export {

    if !@chars {
        return Nil;
    }

    without $bottomVal {
        $bottomVal = $val;
    }

    # First node
    my ML::TriesWithFrequencies::Trie $res = ML::TriesWithFrequencies::Trie.new(@chars[*- 1], $bottomVal);

    # Is this faster: @chars.head(@chars.elems-1).reverse;
    for @chars[^(*- 1)].reverse -> $c {
        my %children = $res.getKey() => $res;
        $res = ML::TriesWithFrequencies::Trie.new($c, $val, %children);
    }

    my ML::TriesWithFrequencies::Trie $res2 = ML::TriesWithFrequencies::Trie.new($TrieRoot, $val);
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
                ML::TriesWithFrequencies::Trie.new($TrieRoot, $tr1.value, %($TrieRoot => $tr1.children)),
                ML::TriesWithFrequencies::Trie.new($TrieRoot, $tr2.value, %($TrieRoot => $tr2.children)));

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
                @word where $_.all ~~ Str,
                Numeric $value = 1.0,
                Numeric $bottomVal?
        --> ML::TriesWithFrequencies::Trie) is export {
    with $bottomVal {
        trie-merge($tr, trie-make(@word, $value, $bottomVal))
    } else {
        trie-merge($tr, trie-make(@word, $value))
    }
}

#--------------------------------------------------------

#| Creates a trie from a given list of list of strings. (Non-recursively.)
sub trie-create1(@words where $_.all ~~ Positional --> ML::TriesWithFrequencies::Trie) {

    if !(@words.defined and @words) {
        return Nil;
    }

    my ML::TriesWithFrequencies::Trie $res = trie-make(@words[0]);

    for @words[1 .. (*- 1)] -> @w {
        $res = trie-insert($res, @w);
    }

    return $res;
}

#--------------------------------------------------------
#| Creates a trie from a given list of list of strings. (Recursively.)
sub trie-create(@words where $_.all ~~ Positional --> ML::TriesWithFrequencies::Trie) is export {

    if !(@words.defined and @words) {
        return Nil;
    }

    if @words.elems <= 15 {
        return trie-create1(@words);
    }

    return trie-merge(
            trie-create(@words[^ceiling(@words.elems / 2)]),
            trie-create(@words[ceiling(@words.elems / 2) .. (@words.elems - 1)]));
}

#--------------------------------------------------------
#| Creates a trie by splitting each of the strings in the given list of strings.
proto trie-create-by-split($words, |) is export {*}

multi trie-create-by-split( Str $word, *%args) {
    trie-create-by-split( [$word], |%args )
}

multi trie-create-by-split(@words where $_.all ~~ Str, $splitter = '',  :$skip-empty = True, :$v = False) {
    trie-create(@words.map({ [$_.split($splitter, :skip-empty, :v)] }));
}

#--------------------------------------------------------
#| Converts the counts (frequencies) at the nodes into node probabilities.
#| @param tr a trie object
sub trie-node-probabilities(ML::TriesWithFrequencies::Trie $tr) is export {
    my ML::TriesWithFrequencies::Trie $res = nodeProbabilitiesRec($tr);
    $res.setValue(1.0);
    return $res;
}

#| @description Recursive step function for converting node frequencies into node probabilities.
#| @param tr a trie object
sub nodeProbabilitiesRec(ML::TriesWithFrequencies::Trie $tr) {
    my Numeric $chSum = 0;

    if !$tr.children {
        return ML::TriesWithFrequencies::Trie.new($tr.key, $tr.value);
    }

    if ($tr.value == 0) {
        ## This is a strange case -- that generally should not happen.
        $chSum = 0;
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

    return ML::TriesWithFrequencies::Trie.new($tr.key, $tr.value, %resChildren);
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
                  @word where $_.all ~~ Str
        --> Positional) is export {
    if not (@word.defined and @word) {
        return Nil;
    } else {
        if not $tr.children.defined and $tr.children {
            return Nil;
        }

        my Bool $pos = $tr.children{@word[0]}:exists;

        if not $tr.children{@word[0]}:exists {
            return Nil;
        } else {
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
    }
}

#--------------------------------------------------------
#| @description Retrieval of a sub-trie corresponding to a "word".
#| @param tr a trie object
#| @param word a list of strings
sub trie-retrieve(ML::TriesWithFrequencies::Trie $tr,
                  @word where $_.all ~~ Str
        --> ML::TriesWithFrequencies::Trie) is export {
    if not so @word {
        return $tr;
    } else {
        if not so $tr.children {
            return $tr;
        }

        if not $tr.children{@word[0]}:exists {
            return $tr;
        } else {
            return trie-retrieve($tr.children{@word[0]}, @word[1 .. (@word.elems - 1)]);
        }
    }
}

#--------------------------------------------------------
#| @description For a given trie finds if the retrievable part of a word is complete match.
#| @param tr a trie object
#| @param word a list of strings
#| @details Despite the name this function works on the part of the word that can be found in the trie.
sub trie-has-complete-match(ML::TriesWithFrequencies::Trie $tr,
                            @word where $_.all ~~ Str
        --> Bool) is export {

    if not so $tr { return False }

    my ML::TriesWithFrequencies::Trie $subTr = trie-retrieve($tr, @word);

    if not so $subTr.children {
        return True;
    } else {
        my Numeric $chValue = 0.0;

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
                  @word where $_.all ~~ Str
        --> Bool) is export {

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
                @word where $_.all ~~ Str
        --> Bool) is export {

    my $pos = trie-position($tr, @word);

    if not so $pos or $pos.elems < @word.elems {
        return False;
    } else {
        return True;
    }
}

#--------------------------------------------------------
#| Visualize
sub trie-form( ML::TriesWithFrequencies::Trie $tr) is export {
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
use v6.d;

use ML::TriesWithFrequencies::LeafProbabilitiesGatherer;
use ML::TriesWithFrequencies::ParetoBasedRemover;
use ML::TriesWithFrequencies::PathsGatherer;
use ML::TriesWithFrequencies::RegexBasedRemover;
use ML::TriesWithFrequencies::ThresholdBasedRemover;
use ML::TriesWithFrequencies::Trieish;

class ML::TriesWithFrequencies::Trie
        does ML::TriesWithFrequencies::Trieish {

    #--------------------------------------------------------
    method clone(--> ML::TriesWithFrequencies::Trie) {
        ML::TriesWithFrequencies::Trie.new(
                key => self.key,
                value => self.value,
                children => self.children.map({ $_.key => $_.value.clone }))
    }

    ##=======================================================
    ## Core functions -- creation, merging, insertion, node frequencies
    ##=======================================================

    #| @description Makes a base trie from a list
    #| @param chars a list of objects
    #| @param val value (e.g. frequency) to be assigned
    #| @param bottomVal the bottom value
    method make(@chars,
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
            my %children = $res.key => $res;
            $res = ML::TriesWithFrequencies::Trie.new(key => $c, :$value, :%children);
        }

        my ML::TriesWithFrequencies::Trie $res2 = ML::TriesWithFrequencies::Trie.new(key => self.trieRootLabel,
                :$value);
        $res2.children.push: ($res.key => $res);

        return $res2;
    }

    #--------------------------------------------------------
    #| Merge tries.
    proto method merge(|) is export {*}

    multi method merge(ML::TriesWithFrequencies::Trie $tr,
                       Bool :$merge-clones = True
            --> ML::TriesWithFrequencies::Trie) {
        return self.merge(self, $tr, :$merge-clones);
    }

    multi method merge(ML::TriesWithFrequencies::Trie $tr1,
                       ML::TriesWithFrequencies::Trie $tr2,
                       Bool :$merge-clones = True
            --> ML::TriesWithFrequencies::Trie) {

        my ML::TriesWithFrequencies::Trie $res = ML::TriesWithFrequencies::Trie.new;

        if not so $tr1 {

            return $tr2;

        } elsif not so $tr2 {

            return $tr1;

        } elsif $tr1.key ne $tr2.key {

            return self.merge(
                    ML::TriesWithFrequencies::Trie.new(
                            key => self.trieRootLabel,
                            value => $tr1.value,
                            children => %(self.trieRootLabel => $tr1.children)),
                    ML::TriesWithFrequencies::Trie.new(
                            key => self.trieRootLabel,
                            value => $tr2.value,
                            children => %(self.trieRootLabel => $tr2.children)),
                    :$merge-clones);

        } elsif $tr1.key eq $tr2.key {

            if not so $tr1.children {

                return $merge-clones ?? $tr2.clone.setValue($tr1.value + $tr2.value) !! $tr2.setValue($tr1.value + $tr2
                        .value);

            } elsif not so $tr2.children {

                return $merge-clones ?? $tr1.clone.setValue($tr1.value + $tr2.value) !! $tr1.setValue($tr1.value + $tr2
                        .value);

            }

            $res.setKey($tr1.key);
            $res.setValue($tr1.value + $tr2.value);

            # Here we merge using the keys of the smaller hash of children.
            # Hence the two almost identical codes.
            if $tr1.children.elems < $tr2.children.elems {

                $res.setChildren($tr2.children);

                for $tr1.children.keys -> $key1 {

                    if $res.children{$key1}:!exists {
                        $res.children.push: $tr1.children{$key1}:p;
                    } else {
                        $res.children{$key1} = self.merge($tr1.children{$key1}, $res.children{$key1}, :$merge-clones);
                    }
                }

            } else {

                $res.setChildren($tr1.children);

                for $tr2.children.keys -> $key2 {

                    if $res.children{$key2}:!exists {
                        $res.children.push: $tr2.children{$key2}:p;
                    } else {
                        $res.children{$key2} = self.merge($tr2.children{$key2}, $res.children{$key2}, :$merge-clones);
                    }
                }
            }

            return $res;
        }

        return Nil;
    }

    #| Inserts a "word" (a list of strings) into a trie with a given associated value.
    method insert(@word,
                  Num :$value = 1e0,
                  Num :$bottomValue = 1e0,
                  Bool :$verify-input = True,
                  Bool :$merge-clones = True
            --> ML::TriesWithFrequencies::Trie) is export {

        if $verify-input and not @word.all ~~ Str {
            die "The first argument is expected to be a positional of strings."
        }

        return self.merge(self, self.make(@word, :$value, :$bottomValue, :!verify-input), :$merge-clones);
    }

    #--------------------------------------------------------
    #| Creates a trie from a given list of list of strings. (Non-recursively.)
    sub create1(@words,
                Bool :$verify-input = True
            --> ML::TriesWithFrequencies::Trie) {

        if $verify-input and not @words.all ~~ Positional {
            die "The first argument is expected to be a positional of positionals of strings."
        }

        if not so @words {
            return Nil;
        }

        my ML::TriesWithFrequencies::Trie $res = ML::TriesWithFrequencies::Trie.make(@words[0]);

        for @words[1 .. (@words.elems - 1)] -> @w {
            $res = $res.insert(@w, :$verify-input, :!merge-clones);
        }

        return $res;
    }

    #--------------------------------------------------------
    #| Creates a trie from a given list of list of strings. (Recursively.)
    method create(@words,
                  UInt :$bisection-threshold = 15,
                  Bool :$verify-input = True
            --> ML::TriesWithFrequencies::Trie) is export {

        if not so @words { return Nil; }

        if $verify-input and not @words.all ~~ Positional {
            die "The first argument is expected to be a positional of positionals of strings."
        }

        if @words.elems <= $bisection-threshold {
            return create1(@words, :!verify-input);
        }

        return self.merge(
                self.create(@words[^ceiling(@words.elems / 2)], :$bisection-threshold, :!verify-input),
                self.create(@words[ceiling(@words.elems / 2) .. (@words.elems - 1)], :$bisection-threshold,
                        :!verify-input));
    }

    #--------------------------------------------------------
    #| Creates a trie by splitting each of the strings in the given list of strings.
    proto method create-by-split($words, |) is export {*}

    multi method create-by-split(Str $word, *%args) {
        return self.create-by-split([$word], |%args)
    }

    multi method create-by-split(@words,
                                 :$splitter = '',
                                 :$skip-empty = True,
                                 :$v = False,
                                 UInt :$bisection-threshold = 15
            --> ML::TriesWithFrequencies::Trie) {

        if not so @words { return Nil }

        if not @words.all ~~ Str {
            die "The first argument is expected to be a positional of strings."
        }

        return self.create(@words.map({ [$_.split($splitter, :$skip-empty, :$v)] }), :$bisection-threshold);
    }

    ##========================================================
    ## Trie node-probabilities and related functions
    ##========================================================
    #| Converts the counts (frequencies) at the nodes into node probabilities.
    #| @param tr a trie object
    method node-probabilities() is export {
        my ML::TriesWithFrequencies::Trie $res = nodeProbabilitiesRec(self);
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

    #--------------------------------------------------------
    sub value-total(ML::TriesWithFrequencies::Trie $tr) {
        return [+] $tr.children>>.value;
    }

    #--------------------------------------------------------
    method leaf-probabilities(:$ulp = Whatever, Bool :$normalize = True --> Hash) is export {

        if self.value > 1 && $normalize {
            return self.node-probabilities.leaf-probabilities(:$ulp);
        }

        my $pobj;
        if ($ulp ~~ Numeric) {
            $pobj = ML::TriesWithFrequencies::LeafProbabilitiesGatherer.new(:$ulp);
        } else {
            $pobj = ML::TriesWithFrequencies::LeafProbabilitiesGatherer.new();
        }

        $pobj.counts-trie = self.value > 1;
        $pobj.trie-trace(self)
    }

    ##=======================================================
    ## Retrieval functions
    ##=======================================================

    #--------------------------------------------------------
    #| @description Test is a trie object a leaf.
    method leafQ(--> Bool) is export {
        return not (self.children.defined and self.children)
    }

    sub leafQ(ML::TriesWithFrequencies::Trie $tr --> Bool) {
        return $tr.leafQ;
    }

    #--------------------------------------------------------
    #| @description Find the position of a given word (or part of it) in the trie.
    #| @param tr a trie object
    #| @param word a list of strings
    method position(@word --> Positional) is export {

        if not so @word { return Nil; }

        if not so self.children { return Nil; }

        if not @word.all ~~ Str {
            die "The first argument is expected to be a positional of strings."
        }

        if not self.children{@word[0]}:exists {
            return Nil;
        }

        my @res;
        @res.append(@word[0]);
        my $rpos = self.children{@word[0]}.position(@word[1 .. (@word.elems - 1)]);

        if not ($rpos.defined and $rpos) {
            return @res;
        } else {
            @res.append(|$rpos);
            return @res;
        }
    }

    #--------------------------------------------------------
    #| @description Retrieval of a sub-trie corresponding to a "word".
    proto method retrieve( |
            --> ML::TriesWithFrequencies::Trie) is export {*}

    #| @description Retrieval of a sub-trie corresponding to a "word".
    #| @param $word a string
    multi method retrieve($word
            --> ML::TriesWithFrequencies::Trie) {
        return self.retrieve([$word,]);
    }

    #| @description Retrieval of a sub-trie corresponding to a "word".
    #| @param word a list of strings
    multi method retrieve(@word
            --> ML::TriesWithFrequencies::Trie) {

        if not so @word { return self; }

        if not so self.children { return self; }

        if not @word.all ~~ Str {
            die "The first argument is expected to be a positional of strings."
        }

        if not self.children{@word[0]}:exists {
            return self;
        } else {
            return self.children{@word[0]}.retrieve(@word[1 .. (@word.elems - 1)]);
        }
    }

    #--------------------------------------------------------
    #| @description For a given trie finds if the retrievable part of a word is complete match.
    proto method has-complete-match( | --> Bool) is export {*}

    #| @description For a given trie finds if the retrievable part of a word is complete match.
    #| @param word a list of strings
    multi method has-complete-match($word --> Bool) {
        return self.has-complete-match([$word,]);
    }

    #| @description For a given trie finds if the retrievable part of a word is complete match.
    #| @param word a list of strings
    #| @details Despite the name this function works on the part of the word that can be found in the trie.
    multi method has-complete-match( @word --> Bool) {

        if not so self { return False }

        if not so @word { return False }

        if not @word.all ~~ Str {
            die "The first argument is expected to be a positional of strings."
        }

        my ML::TriesWithFrequencies::Trie $subTr = self.retrieve(@word);

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
    proto method contains(| --> Bool) is export {*}

    #| @description Does the trie object tr contains a word.
    #| @param word a word to be checked
    multi method contains($word --> Bool) {
        self.contains([$word,])
    }

    #| @description Does the trie object tr contains a word.
    #| @param tr a trie object
    #| @param word a word to be checked
    multi method contains(@word --> Bool) {

        if not so @word { return Nil }

        if not @word.all ~~ Str {
            die "The first argument is expected to be a positional of strings."
        }

        my $pos = self.position(@word);

        if not so $pos or $pos.elems < @word.elems {
            return False;
        } else {
            return self.has-complete-match($pos);
        }
    }

    #--------------------------------------------------------
    #| @description Does the trie object tr has a word as key.
    #| @param tr a trie object
    proto method is-key(| --> Bool) is export {*}

    #| @description Does the trie object tr has a word as key.
    #| @param tr a trie object
    #| @param word a word to be checked
    multi method is-key(
    #| A string "word" to test as a key
            $word

            --> Bool) {
        self.is-key([$word,])
    }

    #| @description Does the trie object tr has a word as key.
    #| @param word a word to be checked
    multi method is-key(
    #| A positional "word" to test as a key
            @word

            --> Bool) {

        if not so @word { return Nil }

        if not @word.all ~~ Str {
            die "The first argument is expected to be a positional of strings."
        }

        my $pos = self.position(@word);

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
    #| @param sep A sep to be used when strings are joined.
    #| @param threshold Above what threshold to do the shrinking. If negative automatic shrinking test is applied.
    method shrink(
    #| Separator string to be used when strings are joined.
            Str :$sep = '',

    #| Above what threshold to do the shrinking. If negative automatic shrinking test is applied.
            num :$threshold = -1e0,

    #| Should only internal nodes be shrunk or not?
            Bool :$internal-only = False

            --> ML::TriesWithFrequencies::Trie) is export {
        return shrinkRec(self, $sep, $threshold, $internal-only, 0);
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
        my Bool $rootQ = ($n == 0 and $tr.key eq $tr.trieRootLabel);

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

            if $shrinkQ and (!$internalOnly or $internalOnly and not @arr[0].leafQ) {
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
    #| @return Returns the values for "total", "internal", "leaves".
    method node-counts(--> Hash) is export {
        ## The result would like { "total"->23, "internal"->12, "leaves"->11 }.

        my $res = nodeCountsRec(self, 0, 0);

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
    method remove-by-threshold (
    #| Threshold
            Numeric $threshold,

    #| Should nodes with values below the threshold be removed or not?
            Bool :$below-threshold = True,

    #| Name of the aggregation node with value that equals the removed sum.
            Str :$postfix = ''

            --> ML::TriesWithFrequencies::Trie) is export {

        my $robj = ML::TriesWithFrequencies::ThresholdBasedRemover.new(threshold => $threshold.Num, :$below-threshold, :$postfix);

        $robj.trie-threshold-remove(self)
    }

    #--------------------------------------------------------
    #| Remove nodes by Pareto fraction.
    method remove-by-pareto-fraction (
    #| Pareto fraction
            Numeric $fraction,

    #| Should bottom nodes be removed or not?
            Bool :$bottom = True,

    #| Name of the aggregation node with value that equals the removed sum.
            Str :$postfix = ''

            --> ML::TriesWithFrequencies::Trie) is export {

        my $robj = ML::TriesWithFrequencies::ParetoBasedRemover.new(pareto-fraction => $fraction.Num,
                remove-bottom => $bottom, :$postfix);

        return $robj.trie-pareto-remove(self);
    }

    #--------------------------------------------------------
    #| Remove nodes by regex.
    method remove-by-regex (
    #| Regex
            $key-pattern,

    #| Should the regex be inverted or not?
            Bool :$invert = False,

    #| Name of the aggregation node with value that equals the removed sum.
            Str :$postfix = ''

            --> ML::TriesWithFrequencies::Trie) is export {

        my $robj = ML::TriesWithFrequencies::RegexBasedRemover.new(:$key-pattern, :$invert, :$postfix);

        $robj.trie-regex-remove(self)
    }


    ##=======================================================
    ## Selection functions
    ##=======================================================

    #--------------------------------------------------------
    #| Select nodes by threshold.
    method select-by-threshold (
    #| Threshold
            Numeric $threshold,

    #| Should nodes with values above the threshold be selected or not?
            Bool :$above-threshold = True,

    #| Name of the aggregation node with value that equals the removed sum.
            Str :$postfix = ''

            --> ML::TriesWithFrequencies::Trie) is export {
        return self.remove-by-threshold($threshold, below-threshold => $above-threshold, :$postfix);
    }

    #--------------------------------------------------------
    #| Select nodes by Pareto fraction.
    method select-by-pareto-fraction (
    #| Pareto fraction
            Numeric $fraction,

    #| Should top nodes be selected or not?
            Bool :$top = True,

    #| Name of the aggregation node with value that equals the removed sum.
            Str :$postfix = ''

            --> ML::TriesWithFrequencies::Trie) is export {
        return self.remove-by-pareto-fraction($fraction, bottom => $$top, :$postfix);
    }

    #--------------------------------------------------------
    #| Select nodes by regex.
    method select-by-regex (
    #| Pareto fraction
            $key-pattern,

    #| Should the regex be inverted or not?
            Bool :$invert = False,

    #| Name of the aggregation node with value that equal the removed sum.
            Str :$postfix = ''

            --> ML::TriesWithFrequencies::Trie) is export {
        return self.remove-by-regex($key-pattern, invert => !$invert, :$postfix);
    }

    ##=======================================================
    ## Path functions
    ##=======================================================
    #| @description Finds the paths from the root of a trie to the leaves.
    #| @param tr a trie object
    method root-to-leaf-paths(:$ulp = Whatever --> Positional) is export {

        my $pobj;
        if ($ulp ~~ Numeric) {
            $pobj = ML::TriesWithFrequencies::PathsGatherer.new(:$ulp);
        } else {
            $pobj = ML::TriesWithFrequencies::PathsGatherer.new();
        }

        $pobj.trie-trace(self)
    }

    ##-------------------------------------------------------
    proto method words(| --> Positional) is export {*};

    #| @description Finds all words in the trie tr that start with the word searchWord.
    #| @param sw a list of strings
    #| @param sep is a separator
    multi method words($sw, :$sep = Whatever --> Positional) {
        return self.retrieve($sw).words(:$sep);
    }

    #| @description Finds all words in the trie tr that start with the word searchWord.
    #| @param sep is a separator
    multi method words(:$sep = Whatever --> Positional) {

        my $res = self.root-to-leaf-paths(:$sep).map({ $_».key.grep({ $_ ne self.trieRootLabel }) });

        if $sep.isa(Str) { $res».join($sep).List }
        else { $res.List>>.List }
    }

    ##-------------------------------------------------------
    #| @description Finds all words in the trie tr that start with the word searchWord.
    #| @param sep is a separator
    method words-with-probabilities(:$sep = Whatever) is export {

        my @res = self.root-to-leaf-paths;
        my @words = @res.map({ $_».key.grep({ $_ ne self.trieRootLabel }) });
        my @probs = @res.map({ [*] $_».value });

        if $sep.isa(Str) { @words».join($sep) Z=> @probs }
        else { @words Z=> @probs }
    }

    ##=======================================================
    ## Classification
    ##=======================================================
    sub is-array-of-arrays($obj) is export {
        $obj ~~ Positional and ( [and] $obj.map({ $_ ~~ Positional }) )
    }

    #------------------------------------------------------------
    proto method classify(@record, :$prop = 'Decision', :$default = Nil, Bool :$verify-key-existence = True) is export {*}

    multi method classify(@record, :$prop is copy = 'Decision', :$default = Empty, Bool :$verify-key-existence = True) {

        if $prop.isa(Whatever) { $prop = 'Values'; }

        if is-array-of-arrays(@record) {
            return @record.map({ self.classify($_, :$prop, :$default, :$verify-key-existence) });
        }

        my %res = %();
        if $verify-key-existence && !self.is-key(@record) {
            warn "The first argument {@record.raku} is not key in the trie.";
        } else {

            my ML::TriesWithFrequencies::Trie $trRes = self.retrieve(@record);

            my $normalize = !($prop ~~ Str && $prop.lc (elem) <value values>);
            %res = $trRes.leaf-probabilities(:$normalize);
        }

        my $sum = %res.values.sum;
        if $sum == 0e0 { $sum = 1; }

        given $prop {
            when $_ ~~ Str && $_.lc eq 'decision' { return %res ?? %res.pairs.sort(-*.value).head.key !! Whatever; }
            when $_ ~~ Str && $_.lc (elem) <value values> { return %res; }
            when $_ ~~ Str && $_.lc (elem) <probabilities probs> { return %res ?? %res.deepmap({ $_ / $sum }) !! { $default.Str => 0 }; }
            when $_ ~~ Pair && $_.key.lc (elem) <probability prob> { return %res{$_.value}:exists ?? %res{$_.value} / $sum !! 0; }
            default {
                warn "Unknown property specification $prop.";
                return %res;
            }
        }
    }

    ##=======================================================
    ## Echo
    ##=======================================================
    ## AKA, "in pipeline echoing" or "say within a pipeline".

    method echo($pre = '', $post = '', :&f is copy = WhateverCode) {

        if &f.isa(WhateverCode) { &f = { $_ ~~ Str ?? say $_ !! say $_.form; $_ } }

        if $pre { &f($pre); }
        &f(self);
        if $post { &f($post); }

        return self;
    }

    ##=======================================================
    ## Echo function
    ##=======================================================
    
    method echo-function(&func is copy = WhateverCode) {

        if &func.isa(WhateverCode) { &func = { $_ ~~ Str ?? say $_ !! say $_.form; $_ } }

        &func(self);

        return self;
    }

    ##=======================================================
    ## Representation functions
    ##=======================================================

    #--------------------------------------------------------
    #| From Map/Hash format
    multi method from-map-format( %tr --> ML::TriesWithFrequencies::Trie ) {
        if %tr{$.trieRootLabel}:exists {
            return self.from-map-format(%tr{$.trieRootLabel}:p)
        } else {
            die "Cannot find {$.trieRootLabel}."
        }
    }

    multi method from-map-format( Pair $trBody --> ML::TriesWithFrequencies::Trie ) {

        if $trBody.key ~~ Str {
            self.setKey($trBody.key);
            if $trBody.value{$.trieValueLabel}:exists {
                self.setValue($trBody.value{$.trieValueLabel});
                if $trBody.value.elems > 1 {
                    %!children = $trBody.value.grep({ $_.key ne $.trieValueLabel }).map({
                        my ML::TriesWithFrequencies::Trie $ch .= new;
                        $_.key => $ch.from-map-format($_)
                    })
                }
            } else {
                die "Cannot find {$.trieValueLabel}."
            }
        } else {
            die "Cannot use non-string trie key."
        }

        return self;
    }

    #--------------------------------------------------------
    #| From JSON-Map format
    multi method from-json-map-format( %tr --> ML::TriesWithFrequencies::Trie ) {
        if (%tr<key>:exists) && (%tr<value>:exists) && (%tr<children>:exists) {

            if %tr<children> !~~ Positional {
                die 'The values of the "children" are expected to be Positional objects.';
            }

            if %tr<children> {

                my %children = %tr<children>.map(-> $c {
                    my ML::TriesWithFrequencies::Trie $node .= new;
                    $node.from-json-map-format($c);
                    $node.getKey => $node
                }).Hash;

                self.setChildren(%children);
            }

            self.setKey(%tr<key>);
            self.setValue(%tr<value>.Num);

            return self;

        } else {
            die 'Cannot find the keys ' ~ <key value children>.raku ~ '.';
        }
    }

    ##=======================================================
    ## Visualization functions
    ##=======================================================

    #--------------------------------------------------------
    #| Visualize
    method form(
    #| A string that is the left boundary marker of a node
            Str :$lb = '',

    #| A string that separates the key and value of a node
            Str :$sep = ' => ',

    #| A string that is the right boundary marker of a node
            Str :$rb = '',

    #| Should key-value nodes be used not?
            Bool :$key-value-nodes = True) is export {
        my $res = visualize-tree(self.toMapFormat.first, *.key, *.value.List, :$lb, :$sep, :$rb, :$key-value-nodes, trieValueLabel => self.trieValueLabel);
        return $res.join("\n");
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
                       Bool :$key-value-nodes = True,
                       Str :$trieValueLabel = 'VALUE';
                       ) {
        sub visit($node, *@pre) {
            my $suffix = '';
            if $key-value-nodes and $node.value.isa(Hash) and $node.value{$trieValueLabel}:exists {
                $suffix = $sep ~ $node.value{$trieValueLabel}
            }
            gather {
                if $node.&label ~~ $trieValueLabel {
                    if not $key-value-nodes {
                        take @pre[0] ~ $node.value
                    }
                } else {
                    take @pre[0] ~ $lb ~ $node.&label ~ $suffix ~ $rb;
                    my @children = sort $node.&children.grep({ $_.key ne $trieValueLabel });
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

}
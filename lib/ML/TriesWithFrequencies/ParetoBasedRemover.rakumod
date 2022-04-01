use ML::TriesWithFrequencies::Trie;
use ML::TriesWithFrequencies::TrieTraverse;

class ML::TriesWithFrequencies::ParetoBasedRemover
        does ML::TriesWithFrequencies::TrieTraverse {

    has Num $.pareto-fraction = 0e8;
    has Bool $.remove-bottom = True;
    has Str $.postfix = '';

    #--------------------------------------------------------
    method new(Num :$pareto-fraction = 1e0, Bool :$remove-bottom = True, Str :$postfix = '') {
        self.bless(:$pareto-fraction, :$remove-bottom, :$postfix)
    }

    #--------------------------------------------------------
    method remove(
            ML::TriesWithFrequencies::Trie $tr,
            --> ML::TriesWithFrequencies::Trie) {
        if not so $tr.children {

            return $tr.clone()

        } else {

            my ML::TriesWithFrequencies::Trie %resChildren = %();

            my Num $removedSum = 0e0;
            my Num $cumSum = 0e0;
            my Num $threshold = 0e0;

            my ML::TriesWithFrequencies::Trie @children = $tr.children.values;

            ## Calculate the cumulative sum
            for @children -> $v {
                $cumSum += $v.value;
            }

            ## Sort the children in descending order
            @children = @children.sort(-> $a, $b {$b.value > $a.value});

            ## Determine threshold
            $threshold = $!pareto-fraction * $cumSum;

            # Pick children (using the sorted list of children above)
            $removedSum = 0e0; $cumSum = 0e0;
            for @children.kv -> $k, $v {

                if $!remove-bottom and $cumSum ≤ $threshold or
                        not $!remove-bottom and $cumSum > $threshold {

                    %resChildren.push: ($k => $v)

                } else {

                    if $!postfix {
                        $removedSum += $v.value;
                    }
                }

                $cumSum += $v.value
            }

            # Make node for the removed (if postfix is a non-empty string)
            if $!postfix and $removedSum > 0 {
                %resChildren.push: ($!postfix => ML::TriesWithFrequencies::Trie.new(key => $!postfix, value => $removedSum))
            }

            # Result
            return ML::TriesWithFrequencies::Trie.new(key => $tr.key, value => $tr.value, children => %resChildren)
        }
    }


    #--------------------------------------------------------
    method trie-pareto-remove(ML::TriesWithFrequencies::Trie $tr) {
        my sub preFunc( ML::TriesWithFrequencies::Trie $tr) { self.remove($tr) }
        my sub postFunc(ML::TriesWithFrequencies::Trie $tr) { $tr };
        self.trie-map($tr, &preFunc, WhateverCode, 1)
    }
}

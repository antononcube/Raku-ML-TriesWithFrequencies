use ML::TriesWithFrequencies::Trieish;
use ML::TriesWithFrequencies::TrieTraverse;

class ML::TriesWithFrequencies::ThresholdBasedRemover
        does ML::TriesWithFrequencies::TrieTraverse {

    has Num $.threshold = 1e0;
    has Bool $.below-threshold = True;
    has Str $.postfix = '';

    #--------------------------------------------------------
    method new(Num :$threshold = 1e0, Bool :$below-threshold = True, Str :$postfix = '') {
        self.bless(:$threshold, :$below-threshold, :$postfix)
    }

    #--------------------------------------------------------
    method remove(
            ML::TriesWithFrequencies::Trieish $tr,
            --> ML::TriesWithFrequencies::Trieish) {
        if not so $tr.children {

            return $tr.clone()

        } else {

            my ML::TriesWithFrequencies::Trieish %resChildren = %();
            my Num $removedSum = 0e0;

            # Pick children
            for $tr.children.kv -> $k, $v {

                if $!below-threshold and $v.value ≥ $!threshold or
                        not $!below-threshold and $v.value < $!threshold {

                    %resChildren.push: ($k => $v)

                } else {

                    if $!postfix {
                        $removedSum += $v.value;
                    }
                }
            }

            # Make node for the removed (if postfix is a non-empty string)
            if $!postfix and $removedSum > 0 {
                %resChildren.push: ($!postfix => $tr.new(key => $!postfix, value => $removedSum))
            }

#            say 'in remove::', %resChildren;

            # Result
            return $tr.new(key => $tr.key, value => $tr.value, children => %resChildren)
        }
    }


    #--------------------------------------------------------
    method trie-threshold-remove(ML::TriesWithFrequencies::Trieish $tr) {
        my sub preFunc( ML::TriesWithFrequencies::Trieish $tr) { self.remove($tr) }
        my sub postFunc(ML::TriesWithFrequencies::Trieish $tr) { $tr };
        self.trie-map($tr, &preFunc, WhateverCode, 1)
    }
}

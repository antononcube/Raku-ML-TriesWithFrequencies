use ML::TriesWithFrequencies::Trie;
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
    method kvFunc(Str $k, ML::TriesWithFrequencies::Trie $tr --> Pair) {
        note 'Not used, not implemented.';
        Pair('Not', Whatever)
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

#            say 'in remove:: ', $tr.children.gist;

            # Pick children
            for $tr.children.kv -> $k, $v {

#                say 'in remove:: $k: ', $k;
#                say 'in remove:: $v.value: ', $v.value;
#                say 'in remove:: $!threshold: ', $!threshold;
#                say 'in remove:: check: ', ($!below-threshold and ($v.value ≥ $!threshold));

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
                %resChildren.push: ($!postfix => ML::TriesWithFrequencies::Trie.new(key => $!postfix, value => $removedSum))
            }

#            say 'in remove::', %resChildren;

            # Result
            return ML::TriesWithFrequencies::Trie.new(key => $tr.key, value => $tr.value, children => %resChildren)
        }
    }


    #--------------------------------------------------------
    method trie-threshold-remove(ML::TriesWithFrequencies::Trie $tr) {
        my sub preFunc( ML::TriesWithFrequencies::Trie $tr) { self.remove($tr) }
        my sub postFunc(ML::TriesWithFrequencies::Trie $tr) { $tr };
        self.trie-map($tr, &preFunc, WhateverCode, 1)
    }
}

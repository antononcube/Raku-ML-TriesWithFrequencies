use ML::TriesWithFrequencies::Trieish;
use ML::TriesWithFrequencies::TrieTraverse;

class ML::TriesWithFrequencies::RegexBasedRemover
        does ML::TriesWithFrequencies::TrieTraverse {

    has $.key-pattern;
    has Bool $.invert = False;
    has Str $.postfix = '';

    #--------------------------------------------------------
    method new(:$key-pattern, Bool :$invert = False, Str :$postfix = '') {
        self.bless(:$key-pattern, :$invert, :$postfix)
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

                if not $!invert and !($k ~~ $!key-pattern) or
                        $!invert and ($k ~~ $!key-pattern) {

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
    method trie-regex-remove(ML::TriesWithFrequencies::Trieish $tr) {
        my sub preFunc( ML::TriesWithFrequencies::Trieish $tr) { self.remove($tr) }
        my sub postFunc(ML::TriesWithFrequencies::Trieish $tr) { $tr };
        self.trie-map($tr, &preFunc, WhateverCode, 1)
    }
}

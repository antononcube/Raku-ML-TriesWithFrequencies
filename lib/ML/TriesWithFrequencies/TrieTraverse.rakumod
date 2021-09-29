use ML::TriesWithFrequencies::Trie;

role ML::TriesWithFrequencies::TrieTraverse {

    #--------------------------------------------------------
    method kvFunc(Str $k, ML::TriesWithFrequencies::Trie $tr --> Pair) {!!!};

    #--------------------------------------------------------
    #| Traver trie with a key-value function.
    multi method trie-map(
    #| Trie to be traversed
            ML::TriesWithFrequencies::Trie $tr,

    #| Returns a Pair of Str to Num
            &kvFunc,


    #| Recursion level
            UInt $level

            --> ML::TriesWithFrequencies::Trie) {
        if not so $tr {

            return Nil;

        } elsif not so &kvFunc {

            return $tr.clone();

        } elsif not so $tr.children {

            my Pair $pres = &kvFunc($tr.key, $tr.value);

            return ML::TriesWithFrequencies::Trie.new(key => $pres.key, value => $pres.value)

        } else {

            my ML::TriesWithFrequencies::Trie %resChildren = %();

            for $tr.children.kv -> $k, $v {

                my ML::TriesWithFrequencies::Trie $chNode = self.trie-map($v, &kvFunc, $level + 1);

                %resChildren.push: ($k, $chNode);
            }

            my Pair $pres = &kvFunc($tr.key, $tr.value);

            return ML::TriesWithFrequencies::Trie.new(key => $pres.key, value => $pres.value, children => %resChildren);
        }
    }

    #--------------------------------------------------------
    #| Traver trie with a pre- and post- node functions.
    multi method trie-map(
    #| Trie to be traversed
            ML::TriesWithFrequencies::Trie $tr,

    #| Takes and returns a Trie
            &preFunc,

    #| Take and returns a Trie
            &postFunc,

    #| Recursion level
            UInt $level

            --> ML::TriesWithFrequencies::Trie) {
        if not so $tr {

            return Nil;

        } elsif not so &preFunc and not so &postFunc {

            return $tr.clone();

        } else {

            my ML::TriesWithFrequencies::Trie $res;

            if &preFunc.isa(WhateverCode) or not so &preFunc {
                $res = $tr
            } else {
                $res = &preFunc($tr)
            }

            my ML::TriesWithFrequencies::Trie %resChildren = %();

            if so $res.children {

                for $res.children.kv -> $k, $v {

                    my ML::TriesWithFrequencies::Trie $chNode = self.trie-map($v, &preFunc, &postFunc, $level + 1);

                    %resChildren.push: ($k, $chNode);
                }
            }

            $res.setChildren(%resChildren);

            if not (&postFunc.isa(WhateverCode) or not so &postFunc) {
                $res = &postFunc($res)
            };

            return $res;
        }
    }
}

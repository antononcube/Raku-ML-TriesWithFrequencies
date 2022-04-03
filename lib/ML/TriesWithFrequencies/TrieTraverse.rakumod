use ML::TriesWithFrequencies::Trieish;

role ML::TriesWithFrequencies::TrieTraverse {

    #--------------------------------------------------------
    #| Traverse trie with a key-value function.
    multi method trie-map(
    #| Trie to be traversed
            ML::TriesWithFrequencies::Trieish $tr,

    #| Returns a Pair of Str to Num
            &kvFunc,


    #| Recursion level
            UInt $level

            --> ML::TriesWithFrequencies::Trieish) {
        if not so $tr {

            return Nil;

        } elsif not so &kvFunc {

            return $tr.clone();

        } elsif not so $tr.children {

            my Pair $pres = &kvFunc($tr.key, $tr.value);

            return ML::TriesWithFrequencies::Trieish.new(key => $pres.key, value => $pres.value)

        } else {

            my ML::TriesWithFrequencies::Trieish %resChildren = %();

            for $tr.children.kv -> $k, $v {

                my ML::TriesWithFrequencies::Trieish $chNode = self.trie-map($v, &kvFunc, $level + 1);

                %resChildren.push: ($k, $chNode);
            }

            my Pair $pres = &kvFunc($tr.key, $tr.value);

            return ML::TriesWithFrequencies::Trieish.new(key => $pres.key, value => $pres.value, children => %resChildren);
        }
    }

    #--------------------------------------------------------
    #| Traverse trie with a pre- and post- node functions.
    multi method trie-map(
    #| Trie to be traversed
            ML::TriesWithFrequencies::Trieish $tr,

    #| Takes and returns a Trie
            &preFunc,

    #| Take and returns a Trie
            &postFunc,

    #| Recursion level
            UInt $level

            --> ML::TriesWithFrequencies::Trieish) {
        if not so $tr {

            return Nil;

        } elsif not so &preFunc and not so &postFunc {

            return $tr.clone();

        } else {

            my ML::TriesWithFrequencies::Trieish $res;

            if &preFunc.isa(WhateverCode) or not so &preFunc {
                $res = $tr
            } else {
                $res = &preFunc($tr)
            }

            my ML::TriesWithFrequencies::Trieish %resChildren = %();

            if so $res.children {

                for $res.children.kv -> $k, $v {

                    my ML::TriesWithFrequencies::Trieish $chNode = self.trie-map($v, &preFunc, &postFunc, $level + 1);

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

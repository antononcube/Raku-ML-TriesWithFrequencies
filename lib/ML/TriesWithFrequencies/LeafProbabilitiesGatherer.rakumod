use ML::TriesWithFrequencies::Trieish;

class ML::TriesWithFrequencies::LeafProbabilitiesGatherer {

    has Numeric $.ulp = 2.220446049250313e-16;
    has Bool $.counts-trie is rw = False;

    #--------------------------------------------------------
    method new() {
        self.bless()
    }

    #--------------------------------------------------------
    method trace(
            ML::TriesWithFrequencies::Trieish $tr,
            UInt $level) {
        if not so $tr.children {

            return [$tr.key => $tr.value,];

        } else {

            my @res;
            my Num $sum = 0e0;

            # This should be simpler: [+] $tr.children.values>>.value
            for $tr.children.values -> $ch {
                $sum += $ch.value;
                @res.append(self.trace($ch, $level + 1));
            }

            if $.counts-trie {
                if $sum < $tr.value && $tr.children.elems > 0 {
                    @res.append($tr.key => $tr.value - $sum);
                }
            } else {
                if $sum + 2.0 * $!ulp < 1.0 && $tr.children.elems > 0 {
                    @res.append($tr.key => 1 - $sum);
                }
            }

            my @res2;

            for @res -> $elem {
                if $.counts-trie {
                    @res2.append([$elem.key => $elem.value,])
                } else {
                    @res2.append([$elem.key => $elem.value * $tr.value,])
                }
            }

            return @res2;
        }
    }


    #--------------------------------------------------------
    method trie-trace(ML::TriesWithFrequencies::Trieish $tr -->Hash) {
        my @res = self.trace($tr, 1);
        return @res.categorize({ $_.key }).deepmap({ $_.value })>>.sum;
    }
}

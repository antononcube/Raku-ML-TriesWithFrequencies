use ML::TriesWithFrequencies::Trie;

class ML::TriesWithFrequencies::PathsGatherer {

    has @.tracedPaths;

    #--------------------------------------------------------
    method new() {
        self.bless()
    }

    #--------------------------------------------------------
    method kvFunc(Str $k, ML::TriesWithFrequencies::Trie $tr --> Pair) {
        note 'Not used, not implemented.';
        Pair('Not', Whatever)
    }

    #--------------------------------------------------------
    method trace(
            ML::TriesWithFrequencies::Trie $tr,
            @path) {

        my @currentPath = @path;
        @currentPath.append: ($tr.key => $tr.value);

        if not so $tr.children {

            @!tracedPaths.append($[@currentPath]);

        } else {

            my Num $sum = 0e0;

            for $tr.children.values -> $ch {
                $sum += $ch.value;
            }

            # System.out.println( sum + " " + tr.getValue() );
            if $tr.value >= 1e0 and $sum < $tr.value or
                    $tr.value < 1e0 and $sum < 1e0 {
                @!tracedPaths.append($[@currentPath]);
            }

            for $tr.children.values -> $ch {
                self.trace($ch, @currentPath);
            }
        }
    }


    #--------------------------------------------------------
    method trie-trace(ML::TriesWithFrequencies::Trie $tr) {
        self.trace($tr, []);
        @!tracedPaths
    }
}

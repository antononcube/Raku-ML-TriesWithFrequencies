use ML::TriesWithFrequencies::Trieish;

class ML::TriesWithFrequencies::PathsGatherer {

    has @.tracedPaths;
    has Numeric $.ulp = 2.220446049250313e-16;

    #--------------------------------------------------------
    method new() {
        self.bless()
    }

    #--------------------------------------------------------
    method trace(
            ML::TriesWithFrequencies::Trieish $tr,
            @path) {

        my @currentPath is List = @path;

        if not so $tr.children {

            @!tracedPaths.append($[|@currentPath, $tr.key => $tr.value]);

        } else {

            my Num $sum = 0e0;

            # This should be simpler: [+] $tr.children.values>>.value
            for $tr.children.values -> $ch {
                $sum += $ch.value;
            }

            # System.out.println( sum + " " + tr.getValue() );
            if $tr.value < 1.0 && $sum + 2.0 * $!ulp < 1.0 ||
                    $tr.value >= 1.0 && $sum + $!ulp < $tr.value {
                @!tracedPaths.append($[|@currentPath, $tr.key => $tr.value]);
            }

            for $tr.children.values -> $ch {
                self.trace($ch, $[|@currentPath, $tr.key => $tr.value]);
            }
        }
    }


    #--------------------------------------------------------
    method trie-trace(ML::TriesWithFrequencies::Trieish $tr) {
        self.trace($tr, []);
        @!tracedPaths
    }
}

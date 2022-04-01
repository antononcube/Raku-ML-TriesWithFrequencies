use ML::TriesWithFrequencies::Trie;

class ML::TriesWithFrequencies::PathsGatherer {

    has @.tracedPaths;
    has Numeric $.ulp = 2.220446049250313e-16;

    #--------------------------------------------------------
    method new() {
        self.bless()
    }

    #--------------------------------------------------------
    method trace(
            ML::TriesWithFrequencies::Trie $tr,
            @path) {

        my @currentPath is List = @path;

        if not so $tr.children {

            @!tracedPaths.append($[|@currentPath, $tr.key => $tr.value]);

        } else {

            my Num $sum = 0e0;

            for $tr.children.values -> $ch {
                $sum += $ch.value;
            }

            # System.out.println( sum + " " + tr.getValue() );
            if $sum < ( 1e0 - $!ulp ) || $sum < ($tr.value - $!ulp) {
                @!tracedPaths.append($[|@currentPath, $tr.key => $tr.value]);
            }

            for $tr.children.values -> $ch {
                self.trace($ch, $[|@currentPath, $tr.key => $tr.value]);
            }
        }
    }


    #--------------------------------------------------------
    method trie-trace(ML::TriesWithFrequencies::Trie $tr) {
        self.trace($tr, []);
        @!tracedPaths
    }
}

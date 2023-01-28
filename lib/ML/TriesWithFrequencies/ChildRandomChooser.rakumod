use ML::TriesWithFrequencies::Trieish;

constant $ULP = 2.220446049250313e-16;

# Very close copy of ML::TriesWithFrequencies::PathsGatherer

class ML::TriesWithFrequencies::ChildRandomChooser {

    has @.tracedPaths;
    has Bool $.weighted = True;
    has Numeric $.ulp = $ULP;

    #--------------------------------------------------------
    multi method new() {
        self.bless()
    }

    multi method new(:$weighted) {
        self.bless(:$weighted, ulp => $ULP);
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
                my $th = self.weighted ?? $sum / $tr.value !!  $tr.children.elems / ($tr.children.elems + 1);
                if rand > $th {
                    @!tracedPaths.append($[|@currentPath, $tr.key => $tr.value]);
                    return;
                }
            }

            if $!weighted {
                my $randKey = Mix($tr.children.map({ $_.key }) Z=> $tr.children.map({ $_.value.value })).roll;
                self.trace($tr.children{$randKey}, $[|@currentPath, $tr.key => $tr.value]);
            } else {
                self.trace($tr.children.values.pick(), $[|@currentPath, $tr.key => $tr.value]);
            }
        }
    }


    #--------------------------------------------------------
    method trie-trace(ML::TriesWithFrequencies::Trieish $tr) {
        @!tracedPaths = [];
        self.trace($tr, []);
        @!tracedPaths>>.key
    }
}

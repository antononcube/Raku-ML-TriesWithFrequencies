
class ML::TriesWithFrequencies::Trie {

    my Str $.trieRootLabel = 'TROOT';
    my Str $.trieValueLabel = 'TVALUE';
    has str $.key;
    has num $.value;
    has ML::TriesWithFrequencies::Trie %.children;


    #--------------------------------------------------------
    method getKey() {
        $!key
    }
    method getValue() {
        $!value
    }
    method getChildren() {
        %!children
    }

    #--------------------------------------------------------
    method setKey( $k ) {
        $!key = $k;
        self
    }
    method setValue( $v) {
        $!value = $v;
        self
    }
    method setChildren( %ch ) {
        %!children = %ch;
        self
    }

    #--------------------------------------------------------
    multi method new( Str $key, Num $value = 1e0 ) {
        self.bless(:$key, :$value)
    }

    multi method new( Str $key, Num $value, %children ) {
        self.bless(:$key, :$value, :%children)
    }

    #--------------------------------------------------------
    #| To Map/Hash format
    method toMapFormat( --> Hash ) {
        my %chMap = %();

        with %!children {
            for %!children.kv -> $k, $v {
                %chMap.push: ( $v.toMapFormat() )
            }
        }

        my %res = %( $.trieValueLabel => $!value), %chMap;
        return %( $!key => %res )
    }

    #--------------------------------------------------------
    #| To Map/Hash format
    method toWLFormat( --> Str ) {
        my $res = '<|' ~ self.toWLFormatRec().subst(:g, '"' ~ $.trieRootLabel ~ '"', '$TrieRoot') ~ '|>';
        $res.subst(:g, $.trieValueLabel, '$TrieValue')
    }

    #| To Map/Hash format recursion
    method toWLFormatRec( --> Str ) {
        my @chMap;

        with %!children {
            for %!children.kv -> $k, $v {
                @chMap.append: [ $v.toWLFormatRec() ];
            }
        }

        my $chRes = @chMap ?? ', ' ~ @chMap.join(', ') !! '';
        my $res = '<|' ~ $.trieValueLabel ~ ' -> ' ~ $!value ~ $chRes ~ '|>';
        return '"' ~ $!key ~ '" -> ' ~ $res
    }

    #--------------------------------------------------------
    #| To sting recursive step
    method tostringRec(UInt $n) {
        my str $offset = "";
        my str $childstr = "";
        my $k = 0;

        $offset = ' ' x $n;

        if %!children {
            for %!children.values -> $elem {
                if ($k == 0) {
                    $childstr = "\n" ~ $offset ~ $elem.tostringRec($n + 1);
                } else {
                    $childstr = $childstr ~ ",\n" ~ $offset ~ $elem.tostringRec($n + 1);
                }
                $k++;
            }
        } else {
            $childstr = "";
        }
        return '{ key =>' ~ $!key ~ ', value => ' ~ $!value ~ ', children => ' ~ $childstr ~ '}';
    }

    #--------------------------------------------------------
    #| To sting
    method str( --> Str ) {
        self.gist
    }

    #| To gist
    method gist( --> Str ) {
        self.toMapFormat().gist
    }
}
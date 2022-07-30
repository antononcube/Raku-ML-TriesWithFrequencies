
role ML::TriesWithFrequencies::Trieish {

    my Str $.trieRootLabel = 'TRIEROOT';
    my Str $.trieValueLabel = 'TRIEVALUE';
    has str $.key;
    has num $.value;
    has ML::TriesWithFrequencies::Trieish %.children;


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
    method clone(--> ML::TriesWithFrequencies::Trieish) {
        ML::TriesWithFrequencies::Trieish.new(
                key => self.key,
                value => self.value,
                children => self.children.map({ $_.key => $_.value.clone }) )
    }

    #--------------------------------------------------------
    #| To Map/Hash format
    method to-map-format( --> Hash ) {
        my %chMap = %();

        with %!children {
            for %!children.kv -> $k, $v {
                %chMap.push: ( $v.to-map-format() )
            }
        }

        my %res = %( $.trieValueLabel => $!value), %chMap;
        return %( $!key => %res )
    }

    #--------------------------------------------------------
    #| As Hash
    method hash( --> Hash) {
       self.to-map-format()
    }

    #--------------------------------------------------------
    #| To WL-Association format
    method WL( --> Str ) {
        my $res = '<|' ~ self.toWLFormatRec().subst(:g, '"' ~ $.trieRootLabel ~ '"', '$TrieRoot') ~ '|>';
        $res.subst(:g, $.trieValueLabel, '$TrieValue')
    }

    #| To WL-Association format recursion
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
    #| To XML format
    method XML( --> Str ) {
        self.toXMLFormatRec(0)
    }

    #| To XML format recursion
    method toXMLFormatRec( UInt $n --> Str ) {
        my Str $offset = ' ' x $n;
        my Str $offset1 = $offset ~ ' ';
        my @chMap;

        with %!children {
            for %!children.kv -> $k, $v {
                @chMap.append: [ $v.toXMLFormatRec($n + 1) ];
            }
            @chMap.map({ $offset1 ~ $_ })
        }

        my $chRes = @chMap ?? "\n" ~ @chMap.join("\n") !! '';
        my $res = $offset1 ~ '<' ~ $.trieValueLabel ~ '>' ~ $!value ~ '</' ~ $.trieValueLabel ~ '>' ~ $chRes;
        return $offset ~ '<' ~ $!key ~ '>' ~ "\n" ~ $res ~ "\n" ~ $offset ~ '</' ~ $!key ~ '>'
    }

    #--------------------------------------------------------
    # In order to minimize the dependencies to other libraries (e.g. JSON::Marshal)
    # JSON format is implemented below.

    #| To JSON format
    method JSON( --> Str ) {
        self.toJSONFormatRec(0)
    }

    #| To JSON format recursion
    method toJSONFormatRec( UInt $n --> Str ) {
        my Str $offset = ' ' x $n;
        my Str $offset1 = $offset ~ ' ';
        my @chMap;

        with %!children {
            for %!children.kv -> $k, $v {
                @chMap.append: [ $v.toJSONFormatRec($n + 1) ];
            }
            @chMap.map({ $offset1 ~ $_ })
        }

        my $chRes = @chMap ?? '[' ~ @chMap.join(', ') ~ ']' !! '[]';
        return  '{"key":' ~ '"' ~ $!key ~ '"' ~ ', "value":' ~ $!value ~ ', "children":' ~ $chRes ~ '}';
    }

    #--------------------------------------------------------
    #| To string
    method Str( --> Str ) {
        self.gist
    }

    #| To gist
    method gist( --> Str ) {
        self.to-map-format().gist
    }
}
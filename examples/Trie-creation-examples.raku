#!/usr/bin/env perl6

use lib '.';
use lib './lib';

use ML::TriesWithFrequencies;
use ML::TriesWithFrequencies::Trie;

my ML::TriesWithFrequencies::Trie ($tr1, $tr2);


say trie-node-probabilities(trie-create-by-split(<bar barman bask bell best>)).toMapFormat.raku;

my $tr = trie-create-by-split( <bar barman bask bell best> );
my $ptr = trie-node-probabilities( $tr );
#trie-say($tr);

#say trie-shrink( $tr ).toWLFormat;
#trie-say( trie-shrink( $ptr ) );
#trie-say( trie-shrink( $ptr, delimiter => '~' ) );

trie-say(trie-retrieve($ptr, 'bar'.comb));

#`(
my $tr1 = trie-make(['bar'.comb]);
#say $tr1.Str;

$tr2 = trie-make(['bam'.comb]);
#say $tr2.Str;

my $tr3 = trie-merge($tr1, $tr2);
#say $tr3.toMapFormat;

my $tr4 = trie-insert( $tr3, ['balk'.comb]);
#say $tr4.toMapFormat;

my $tr5 = trie-create(<bar barman bask bell best>.map({[ $_.comb ]}) );
say $tr5.Str;
trie-say( $tr5);
say $tr5.toWLFormat;

my $tr6 = trie-create-by-split(<bar barman bask bell best>);
#say $tr6.toMapFormat;
#say $tr6.toWLFormat;

#say $tr5 eqv $tr6;
#say trie-node-probabilities($tr5).toWLFormat;

say '-' x 30;

#say trie-position( $tr5, ['baza'.comb]);
#say trie-retrieve( $tr5, ['baza'.comb]).toWLFormat;
say <baza bar bell car>.map({ trie-has-complete-match( $tr5, [$_.comb] ) });
say <baza ba bell car>.map({ trie-contains( $tr5, [$_.comb] ) });
say <baza ba bell car>.map({ trie-is-key( $tr5, [$_.comb] ) });
)
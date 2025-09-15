#use Grammar::Tracer;

grammar DecimalExponent {
    token TOP         { ^ <exponential> $ }
    token exponential { <sign>? <whole> [ '.' <decimal>+ ]? <[eE]> <exponent>? }

    token whole       { <digs>+ }
    token decimal     { <digs>+ }
    token exponent    { <sign>? <digs>+ }

    token sign        { <[+-]> }
    token digs        { <[0..9]> }
}

class DecimalActions {
    method TOP($/) {
        make $<exponential>.made;
    }

    method exponential($/) {
        my Int() $sign = 1;
        with $<sign> {
            if .Str eq '-' { $sign = -1 }
        }

        my Int() $whole    = $<whole>.Str;
        my Int() $decimal  = $<decimal>.Str;
        my Int() $adjust   = $<decimal>.Str.chars;
        my Int() $exponent = $<exponent>.Str;

        my $shift = $adjust - $exponent;
        my $left = $shift >=0 ?? True !! False;

        my $adjusted = $sign * ( ( $whole * 10**$adjust ) + $decimal);

        if $left {
            make FatRat.new($adjusted, 10**$shift);
        } else {
            make FatRat.new($adjusted * 10**-$shift, 1);
        }
    }
}

class FatRatStr {
#class FatRatStr is Allomorph is FatRat {    #tbd
    has FatRat $!fatrat is built handles <nude FatRat Numeric>;
    has Str    $!str    is built handles <Str>;
}

use MONKEY-TYPING;

augment class NumStr {
    method FatRatStr(NumStr:D: --> FatRatStr:D) {
        my $m = DecimalExponent.parse(self.Str, :actions(DecimalActions));
        FatRatStr.new(fatrat => $m.made, str => self.Str);
    }
}

augment class Str {
    method FatRatStr(Str:D: --> FatRatStr:D) {
        my $m = DecimalExponent.parse(self, :actions(DecimalActions));
        FatRatStr.new(fatrat => $m.made, str => self);
    }
}

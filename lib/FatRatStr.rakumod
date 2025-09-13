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
        my $sign = 1;
        with $<sign> {
            if .Str eq '-' { $sign = -1 }
        }

        my $whole    = $<whole>.Str;
        my $decimal  = $<decimal>.Str;
        my $exponent = $<exponent>.Str;

        my $adjust   = $decimal.chars;
        my $shift    = $adjust - $exponent;

        my $numerator   = $sign * ( ( $whole * 10**$adjust ) + $decimal);
        my $denominator = 10**$shift;

        make FatRat.new($numerator, $denominator);
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

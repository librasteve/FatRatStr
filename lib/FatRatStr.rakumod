#use Grammar::Tracer;

grammar DecimalExponent {
    token TOP         { ^ <exponential> $ }
    token exponential { <sign>? <whole> [ '.' <decimal>+ ]? <[eE]> <exponent>? }

    token whole       { \d+ }
    token decimal     { \d+ }
    token exponent    { <[+-]>? \d+ }

    token sign        { <[+-]> }
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
    has FatRat $!fatrat is built handles <nude FatRat Numeric abs Num Int Complex>;
    has Str    $!str    is built;

    method Str {
        my $s = $!str;
        my $sign = '';
        if $s ~~ /^ <[+-]> / { $sign = $s.substr(0, 1); $s = $s.substr(1) }

        my ($mantissa, $epart) = $s.split(/<[eE]>/, 2);
        my $exp = ($epart // '0').Int;

        my ($whole, $frac) = $mantissa.contains('.')
            ?? $mantissa.split('.', 2)
            !! ($mantissa, '');

        my $digits  = $whole ~ $frac;
        my $dec-pos = $whole.chars;

        # find first significant (non-zero) digit position
        my $i = 0;
        $i++ while $i < $digits.chars && $digits.substr($i, 1) eq '0';

        return "{$sign}0e+00" if $i == $digits.chars;

        my $norm-exp = ($dec-pos - 1) - $i + $exp;
        my $sig      = $digits.substr($i);
        my $m        = $sig.substr(0, 1) ~ ($sig.chars > 1 ?? '.' ~ $sig.substr(1) !! '');
        my $e        = $norm-exp >= 0
                           ?? '+' ~ $norm-exp.fmt('%02d')
                           !! '-' ~ $norm-exp.abs.fmt('%02d');

        $sign ~ $m ~ 'e' ~ $e
    }
}

use MONKEY-TYPING;

augment class NumStr {
    method FatRatStr(NumStr:D: --> FatRatStr:D) {
        my $s = self.Str.subst(/'_'/, '', :g);
        my $m = DecimalExponent.parse($s, :actions(DecimalActions));
        FatRatStr.new(fatrat => $m.made, str => self.Str);
    }
}

augment class Str {
    method FatRatStr(Str:D: --> FatRatStr:D) {
        my $s = self.Str.subst(/'_'/, '', :g);
        my $m = DecimalExponent.parse($s, :actions(DecimalActions));
        FatRatStr.new(fatrat => $m.made, str => self);
    }
}

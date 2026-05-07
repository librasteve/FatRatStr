#use Grammar::Tracer;

grammar NumLiteral {
    token TOP         { ^ <exponential> $ }
    token exponential { <sign>? <whole> [ '.' <decimal>+ ]? <[eE]> <exponent>? }

    token whole       { \d+ }
    token decimal     { \d+ }
    token exponent    { <[+-]>? \d+ }

    token sign        { <[+-]> }
}

class NumLiteralActions {
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
    has FatRat $.fatrat handles <nude FatRat Numeric abs Num Int Complex Real>;
    has Str    $.str;

    method TWEAK {
        $!str = FatRatStr.make-str($!fatrat) without $!str;
    }

    method Str { $!str }

    #| make str from fatrat
    multi method make-str(FatRatStr:D: --> Str) {
        FatRatStr.make-str($!fatrat);
    }
    multi method make-str(FatRatStr:U: $fatrat --> Str) {
        my ($num, $den) = $fatrat.nude;

        die "Division by zero" if $den == 0;

        my $sign = ($num < 0) ^ ($den < 0) ?? '-' !! '';
        my $n = $num.abs;
        my $d = $den.abs;

        return '0' if $n == 0;

        # Normalize so that 1 <= n/d < 10
        my $exp = 0;
        while $n >= $d * 10 {
            $d *= 10;
            $exp++;
        }
        while $n < $d {
            $n *= 10;
            $exp--;
        }

        my @digits;
        my %seen;          # remainder → position
        my $remainder = $n;

        while $remainder != 0 && ! (%seen{$remainder}:exists) {
            %seen{$remainder} = @digits.elems;

            my $digit = 0;
            while $remainder >= $d {
                $remainder -= $d;
                $digit++;
            }

            @digits.push($digit);
            $remainder *= 10;
        }

        # Build mantissa
        my $m;
        if @digits.elems == 0 {
            $m = '0';
        } else {
            $m = @digits[0].Str ~ (
            @digits.elems > 1
                ?? '.' ~ @digits[1..*].join
                !! ''
            );
        }

        $sign ~ $m ~ 'e' ~ $exp
    }

    #| round fatrat
    multi method round(FatRatStr:D: Real() $scale --> FatRatStr) {
        FatRatStr.round($!fatrat, $scale);
    }
    multi method round(FatRatStr:U: FatRat $fatrat, Real() $scale=1 --> FatRatStr() ) {

        my $s =  $scale ~~ Num
              ?? $scale.Str.FatRatStr         # avoid 1e-31.FatRat == 0
              !! $scale.FatRat.FatRatStr;     # avoid 0.01.Num eq '0.01'

        die "round: scale cannot be zero" if $s == 0;

        # divide by scale → round → multiply back
        my $q = $fatrat / $s;

        # work in rational space
        my ($n, $d) = $q.nude;

        # integer rounding: n/d → nearest integer
        my $rounded =
            ($n >= 0)
            ?? ($n + $d div 2) div $d
            !! ($n - $d div 2) div $d;

        FatRat.new($rounded, 1) * $s
    }
}

use MONKEY-TYPING;

augment class NumStr {
    method FatRatStr(NumStr:D: --> FatRatStr:D) {
        my $s = self;
        nextsame unless +"$s" ~~ Num;
        $s .= subst(/'_'/, '', :g);
        my $m = NumLiteral.parse($s, :actions(NumLiteralActions));
        FatRatStr.new(fatrat => $m.made, str => ~self);
    }

    multi method FatRat(NumStr:D: --> FatRat:D) {
        my $s = self;
        nextsame unless +"$s" ~~ Num;
        $s .= subst(/'_'/, '', :g);
        my $m = NumLiteral.parse($s, :actions(NumLiteralActions));
        $m.made.FatRat;
    }
}

augment class Str {
    method FatRatStr(Str:D: --> FatRatStr:D) {
        my $s = self;
        nextsame unless +"$s" ~~ Num;
        $s .= subst(/'_'/, '', :g);
        my $m = NumLiteral.parse($s, :actions(NumLiteralActions));
        FatRatStr.new(fatrat => $m.made, str => ~self);
    }

    multi method FatRat(Str:D: --> FatRat:D) {
        my $s = self;
        nextsame unless +"$s" ~~ Num;
        $s .= subst(/'_'/, '', :g);
        my $m = NumLiteral.parse($s, :actions(NumLiteralActions));
        $m.made.FatRat;
    }
}

augment class FatRat {
    method FatRatStr(FatRat:D: --> FatRatStr:D) {
        FatRatStr.new(fatrat => self, str => Str);
    }

    multi method make-str(FatRat:D: --> Str:D) {
        FatRatStr.make-str(self);
    }
}

augment class Num {
    method FatRatStr(Num:D: --> FatRatStr:D) {
        self.Str.FatRatStr //       # need if over/under-flow
        self.FatRat.FatRatStr;      # need if degenerate (e.g. 1250e0)
    }
}

augment class Rat {
    method FatRatStr(Rat:D: --> FatRatStr:D) {
        self.FatRat.FatRatStr;
    }
}

augment class Int {
    method FatRatStr(Int:D: --> FatRatStr:D) {
        self.FatRat.FatRatStr;
    }
}

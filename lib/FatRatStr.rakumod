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
    has FatRat $!fatrat is built handles <nude FatRat Numeric abs Num Int Complex>;
    has Str    $!str    is built;

    method TWEAK {
        $!str = FatRatStr.make-str($!fatrat) without $!str;
    }

    #| make str from fatrat
    multi method make-str(FatRatStr:D:) {
        FatRatStr.make-str($!fatrat);
    }

    multi method make-str(FatRatStr:U: $fatrat) {
        my ($num, $den) = $fatrat.nude;

        die "Division by zero" if $den == 0;

        my $sign = ($num < 0) ^ ($den < 0) ?? '-' !! '';
        my $n = $num.abs;
        my $d = $den.abs;

        return "{$sign}0e+00" if $n == 0;

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

        # Format exponent
        my $e = $exp >= 0
            ?? '+' ~ $exp.fmt('%02d')
            !! '-' ~ $exp.abs.fmt('%02d');

        $sign ~ $m ~ 'e' ~ $e
    }

    method Str { $!str }
}

use MONKEY-TYPING;

augment class NumStr {
    method FatRatStr(NumStr:D: --> FatRatStr:D) {
        my $s = self;
        nextsame unless +"$s" ~~ Num;
        $s .= subst(/'_'/, '', :g);
        my $m = NumLiteral.parse($s, :actions(NumLiteralActions));
        FatRatStr.new(fatrat => $m.made, str => self.Str);
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
        FatRatStr.new(fatrat => $m.made, str => self);
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


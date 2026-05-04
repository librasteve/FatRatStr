# FatRatStr

## Description

FatRat Allomorph to parse NumStr or Str string to FatRat avoiding Num clipping. Provides the `.FatRatStr` coercion method.

The `str` attr contains the original literal. The Num literal is parsed and loaded into the `fatrat` attr.

## Synopsis

```raku
say ~(<9.109_383e309>.FatRatStr * 2).FatRatStr eq '1.8218766e+310';  #True
```

_e309 (and e-325) are the limits of double precision_

## Description

```raku
<1.6605402e-27>.FatRatStr;
#-or-
'1.6605402e-27'.FatRatStr;

#FatRatStr.new(
#    fatrat =>FatRat.new(8302701, 5000000000000000000000000000000000), 
#    str => "1.6605402e-27"
#)
```

Also, to streamline the pattern `'1e-6'.FatRatStr.FatRat;` (to get an actual FatRat), overrides the standard `.FatRat` method of NumStr and Str. 

```raku
<1.6605402e-27>.FatRat;
#-or-
'1.6605402e-27'.FatRat;

#.FatRat @0
#├ $.numerator = 8302701   
#└ $.denominator = 5000000000000000000000000000000000
```

## Notes

If you do FatRatStr math, you need to re-coerce the result from FatRat.

```raku
my $y = <9.109_383_701_5e309>.FatRatStr;
say ~($y *= 2).FatRatStr;

#1.8218767403e+310
```

The method `.round(FatRatStr:D: Real $scale --> FatRatStr) {}` is provided as a utility to do (unlimited precision) rounding.

The class method `FatRatStr.make-str(FatRat:D $f --> Str) {}` is provided as a utility to make the (unlimited precision) string representation.

Copyright 2025 Henley Cloud Consulting Ltd.
Copyright 2026 Stephen Roe


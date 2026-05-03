# FatRatStr

## Description

FatRat Allomorph to parse NumStr or Str string to FatRat avoiding Num clipping. Provides the `.FatRatStr` coercion method.

The `str` attr contains the original literal. The Num literal is parsed and loaded into the `fatrat` attr.

## Synopsis

```raku
<1.6605402e-27>.FatRatStr;
#-or-
'1.6605402e-27'.FatRatStr;

#FatRatStr.new(
#    fatrat =>FatRat.new(8302701, 5000000000000000000000000000000000), 
#    str => "1.6605402e-27"
#)
```

Also, to streamline the pattern `my $x = '1e-6'.FatRatStr.FatRat;` (to get an actual FatRat), overrides the standard `.FatRat` method of NumStr and Str. 

```raku
<1.6605402e-27>.FatRat;
#-or-
'1.6605402e-27'.FatRat;

#.FatRat @0
#├ $.numerator = 8302701   
#└ $.denominator = 5000000000000000000000000000000000
```

Copyright 2025 Henley Cloud Consulting Ltd.
Copyright 2026 Stephen Roe


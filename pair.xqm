(:~
 : Module for a simple pair data structure.
 : @author Leo Wörteler
 : @version 0.1
 :)
module namespace pair = 'http://www.basex.org/pair';

(:~
 : Creates a new pair <code>($fst, $snd)</code>.
 : @param $fst the first partner
 : @param $snd the second partner
 : @return a new pair
 : @example <code>pair:new(42, 7)</code> returns the pair <code>(42, 7)</code>.
 :)
declare function pair:new(
  $a as item()*,
  $b as item()*
) as function(xs:boolean) as item()* {
  function($fst as xs:boolean) as item()* {
    if($fst) then $a else $b
  }
};

(:~
 : Extracts the first element from a pair.
 : @param $pair the pair
 : @return the first element
 : @example <code>pair:fst(pair:new(42, 7))</code> returns <code>42</code>.
 :)
declare function pair:fst(
  $pair as function(xs:boolean) as item()*
) as item()* {
  $pair(true())
};

(:~
 : Extracts the second element from a pair.
 : @param $pair the pair
 : @return the second element
 : @example <code>pair:snd(pair:new(42, 7))</code> returns <code>7</code>.
 :)
declare function pair:snd(
  $pair as function(xs:boolean) as item()*
) as item()* {
  $pair(false())
};

(:~
 : Applies a function to the first element of the pair.
 : @param $f function to apply
 : @param $p the pair
 : @return a pair where <code>$f</code> was applied to the first element
 : @example <code>pair:on-fst(function($x) {2*$x}, pair:new(21, 23))</code>
 :          returns the pair <code>pair:new(42, 23)</code>.
 :)
declare function pair:on-fst(
	$f as function(item()*) as item()*,
  $p as function(xs:boolean) as item()*
) as function(xs:boolean) as item()* {
	(: force evaluation the values before creating the pair :)
	let $x := $f($p(true())), $y := $p(false())
	return function($fst as xs:boolean) as item()* {
    if($fst) then $x else $y
  }
};

(:~
 : Applies a function to the second element of the pair.
 : @param $f function to apply
 : @param $p the pair
 : @return a pair where <code>$f</code> was applied to the second element
 : @example <code>pair:on-snd(function($x) {2*$x}, pair:new(21, 23))</code>
 :          returns the pair <code>pair:new(21, 46)</code>.
 :)
declare function pair:on-snd(
	$f as function(item()*) as item()*,
  $p as function(xs:boolean) as item()*
) as function(xs:boolean) as item()* {
	(: force evaluation the values before creating the pair :)
	let $x := $p(true()), $y := $f($p(false()))
	return function($fst as xs:boolean) as item()* {
    if($fst) then $x else $y
  }
};

(:~
 : Returns a sequence of the first and second partner.
 : @param $p the pair
 : @return the first and second partner concatenated
 : @example <code>pair:to-sequence(pair:new((1, 2), (3, 4)))</code> returns
 :          <code>(1, 2, 3, 4)</code>.
 :)
declare function pair:to-sequence(
  $p as function(xs:boolean) as item()*
) as item()* {
  $p(true()), $p(false())
};

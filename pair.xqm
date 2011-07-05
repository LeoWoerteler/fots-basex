(:~
 : Module for a sinple pair data structure.
 : @author Leo Wörteler
 :)
module namespace pair = 'http://www.basex.org/pair';

declare function pair:new(
  $a as item()*,
  $b as item()*
) as function(xs:boolean) as item()* {
  function($fst as xs:boolean) as item()* {
    if($fst) then $a else $b
  }
};

declare function pair:fst(
  $pair as function(xs:boolean) as item()*
) as item()* {
  $pair(true())
};

declare function pair:snd(
  $pair as function(xs:boolean) as item()*
) as item()* {
  $pair(false())
};

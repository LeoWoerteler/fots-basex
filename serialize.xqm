(:~
 : Module for serializing arbitrary XQuery sequences to strings.
 :
 : @author BaseX Team 2005-11, BSD License
 : @author Leo Wörteler
 : @version 0.1
 :)
module namespace ser = 'http://www.basex.org/serialize';

(:~ Namespace for XQuery Maps as proposed by M. Kay. :)
declare namespace map = "http://www.w3.org/2005/xpath-functions/map";

(:~
 : Serializes an XQuery sequence.
 : @param $seq sequence to serialize
 : @return string representation of <code>$seq</code>
 :)
declare function ser:serialize(
  $seq as item()*
) as xs:string {
  let $strs := map(ser:item#1, $seq)
  return if(count($strs) eq 1) then $strs
    else concat('(', string-join($strs, ', '), ')')
};

(:~
 : Serializes a single XQuery item.
 : @param $it item to serialize
 : @return string representation of <code>$it</code>
 :)
declare function ser:item(
  $it as item()
) as xs:string {
  typeswitch($it)
    case attribute()
      return concat(name($it), '="', $it, '"')
    case node()
      return serialize($it)
    case map(*)
      return ser:map($it)
    case function(*)
      return ser:func($it)
    case xs:untypedAtomic
      return concat('"', replace($it, '"', '""'), '"')
    case xs:string
      return concat('"', replace($it, '"', '""'), '"')
    default
      return xs:string($it)
};

(:~
 : Serializes an XQuery map.
 : @param $map map to serialize
 : @return string representation of <code>$map</code>
 :)
declare function ser:map(
  $map as map(*)
) as xs:string {
  concat(
    'map{',
    string-join(
      for $k in map:keys($map)
      return concat(ser:item($k), ':=',
        ser:serialize($map($k)))
    , ', '),
    '}'
  )
};

(:~
 : Serializes an XQuery function. Anonymous functions are represented by the
 : string '*function*'.
 : @param $func sequence to serialize
 : @return string representation of <code>$func</code>
 :)
declare function ser:func(
  $func as function(*)
) as xs:string {
  let $arity := function-arity($func),
      $name := if(exists(function-name($func)))
        then function-name($func) else '*function*'
  return concat($name, '#', $arity)
};


module namespace ser = 'http://www.basex.org/serialize';

declare function ser:serialize(
  $seq as item()*
) as xs:string {
  let $strs := map(ser:item#1, $seq)
  return if(count($strs) eq 1) then $strs
    else concat('(', string-join($strs, ', '), ')')
};

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

declare function ser:func(
  $func as function(*)
) as xs:string {
  let $arity := function-arity($func),
      $name := if(exists(function-name($func)))
        then function-name($func) else '*function*'
  return concat($name, '#', $arity)
};


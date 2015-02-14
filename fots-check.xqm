(:~
 : Module containing the assertion check used by th QT3 test suite.
 : All assertions are modeled as functions that return the empty sequence
 : on success and a sequence of error descriptions otherwise.
 :
 : @author BaseX Team 2005-11, BSD License
 : @author Leo Wörteler
 : @version 0.1
 :)
module namespace check = "http://www.w3.org/2010/09/qt-fots-catalog/check";

(:~ Small utility module providing an implementation of typed pairs. :)
import module namespace pair='http://www.basex.org/pair' at 'pair.xqm';

(:~ Serialization module. :)
import module namespace ser = 'http://www.basex.org/serialize'
  at 'serialize.xqm';

(:~
 : Checks the given against the expected result.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @return error description if the check failed, empty sequence otherwise
 :)
declare function check:result(
  $eval   as function(xs:string) as item()*,
  $res    as item()*,
  $result as element()
) as element()? {
  let $err := check:res($eval, $res, $result)
  return if(empty($err)) then () else
    <out>
      <result>{ser:serialize($res)}</result>
      <errors>{
        map(function($e){ <error>{$e}</error> }, $err)
      }</errors>
    </out>
};

(:~
 : Checks the given error code against the expected results.
 : @param $code error code
 : @param $error error description
 : @param $result expected result
 : @return error description if the check failed, empty sequence otherwise
 :)
declare function check:error(
  $code   as xs:QName,
  $error  as xs:string?,
  $result as element()
) as element()? {
  let $err := check:err($code, $error, $result)
  return if(empty($err)) then () else
    <out>
      <result>Error: {string-join(('[', $code, ']', $error), ' ')}</result>
      <errors>{
        map(function($e){ <error>{$e}</error> }, $err)
      }</errors>
    </out>
};

(:~
 : Dispatch function for the different assertions.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:res(
  $eval   as function(xs:string) as item()*,
  $res    as item()*,
  $result as element()
) as xs:string* {
  let $test := local-name($result)
  return switch($test)
    case 'all-of'
      return map(check:res($eval, $res, ?), $result/*)
    case 'any-of'
      return check:any-of($eval, $res, $result)
    case 'assert-eq'
      return check:assert-eq($eval, $res, $result)
    case 'assert-type'
      return check:assert-type($eval, $res, $result)
    case 'assert-string-value'
      return check:assert-string-value($res, $result)
    case 'assert-true'
      return check:assert-bool($res, $result, true())
    case 'assert-false'
      return check:assert-bool($res, $result, false())
    case 'assert-deep-eq'
      return check:assert-deep-eq($eval, $res, $result)
    case 'assert-serialization'
      return check:assert-serialization($res, $result)
    case 'assert-permutation'
      return check:assert-permutation($eval, $res, $result)
    case 'assert'
      return check:assert($eval, $res, $result)
    case 'assert-count' 
      return
        let $count := count($res),
            $exp   := xs:integer($result)
        return if($count eq $exp) then ()
          else concat('Expected ', $exp, ' items, found ', $count, '.')
    case 'assert-empty'
      return if(empty($res)) then () else 'Result is not empty.'
    case 'error'
      return concat('Expected Error [', $result/@code, ']')
    default return error(
      fn:QName('http://www.w3.org/2005/xqt-errors', 'FOTS9999'),
        concat('Unknown assertion: "', $test, '"'))
};

(:~
 : Compares the given error code to those expected.
 : @param $code error code
 : @param $error error description
 : @param $result expected result
 : @return possibly empty sequence of errors
 :)
declare function check:err(
  $code as xs:QName,
  $err as xs:string?,
  $result as element()
) as xs:string* {
  let $errors := $result/descendant-or-self::*:error
  return if(exists($errors[@code = xs:string($code)])) then ()
  else if(exists($errors)) then (
    concat('Wrong error code [', $code, '] (', $err, '), expected: [',
      string-join($errors//@code, '], ['), ']')
  ) else (
    concat('Expected result, found error: [', $code, '] ', $err)
  )
};

(:~
 : Checks if any of the child assertions succeed.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:any-of(
  $eval   as function(xs:string) as item()*,
  $res    as item()*,
  $result as element()
) {
  pair:fst(
    fold-left(
      $result/*,
      pair:new((), false()),
      function($p, $n) {
        if(pair:snd($p)) then $p
        else (
          let $r  := check:res($eval, $res, $n),
              $ok := empty($r)
          return pair:new(
            if($ok) then () else (pair:fst($p), $r),
            $ok
          )
        )
      }
    )
  )
};

(:~
 : Checks if the result is the given boolean value.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $exp expected boolean result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert-bool(
  $res as item()*,
  $result as element(),
  $exp as xs:boolean
) {
  if($res instance of xs:boolean and $res eq $exp) then ()
  else concat('Query doesn''t evaluate to ''', $exp, '''')
};

(:~
 : Checks the return value of an arbitrary XQuery query on the result.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert(
  $eval   as function(xs:string) as item()*,
  $res    as item()*,
  $result as element()
) as xs:string* {
  try {
    let $assert :=
      $eval(concat('function($result) { ', xs:string($result), ' }'))
    return if($assert($res)) then ()
      else concat('Assertion ''', $result, ''' failed.')
  } catch * {
    concat('Assertion ''', $result,
      ''' failed with: [', $err:code, '] ', $err:description)
  }
};

(:~
 : Checks if the result has the given type.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert-type(
  $eval   as function(xs:string) as item()*,
  $res    as item()*,
  $result as element()
) as xs:string* {
  try {
    let $type := xs:string($result),
        $test := $eval(concat('function($x) { $x instance of ', $type, ' }'))
    return if($test($res)) then ()
      else concat('Result doesn''t have type ''', $type, '''.')
  } catch * {
    concat('Type check for ''', $result,
      ''' failed with: [', $err:code, '] ', $err:description)
  }
};

(:~
 : Checks if the result is equal to the result of the given XQuery expression.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert-eq(
  $eval   as function(xs:string) as item()*,
  $res    as item()*,
  $result as element()
) as xs:string* {
  try {
    let $exp := $eval($result)
    (: Also check if both are xs:double('NaN') or xs:float('NaN'). :)
    return if($exp eq $res or $exp ne $exp and $res ne $res) then ()
      else concat('Result doesn''t match expected item ''',
        $exp, '''.')
  } catch * {
    concat('Comparison to ''', $result/text(), ''' failed with: [',
      $err:code, '] ', $err:description)
  }
};

(:~
 : Checks if the result has the given string value.
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert-string-value(
  $res as item()*,
  $result as element()
) as xs:string* {
  try {
    let $str := string-join(for $r in $res return string($r), " "),
        $exp := xs:string($result)
    return if($str eq $exp) then ()
      else concat('Expected ''', $exp, ''', found ''', $str, '''.')
  } catch * {
    concat('String comparison to ', $result, ' failed with: [',
      $err:code, '] ', $err:description)
  }
};

(:~
 : Checks if the result is deep-equal to the result of the given expression.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert-deep-eq(
  $eval   as function(xs:string) as item()*,
  $res as item()*,
  $result as element()
) {
  try {
    let $exp := $eval($result)
    return if(deep-equal($res, $exp)) then ()
      else concat('Result is not deep-equal to ''', $result, '''.')
  } catch * {
    concat('Deep comparison to ''', $result, ''' failed with: [',
      $err:code, '] ', $err:description)
  }
};

(:~
 : Checks if the result serializes to the given string.
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert-serialization(
  $res as item()*,
  $result as element()
) {
  try {
    let $ser := serialize(
          ?,
          <output:serialization-parameters xmlns:output="http://www.w3.org/2010/xslt-xquery-serialization">
            <output:method>xml</output:method>
            <output:indent>no</output:indent>
          </output:serialization-parameters>
        ),
        $to-str := function($it) {
          if($it instance of node()) then $ser($it)
          else string($it)
        },
        $act := string-join(map($to-str, $res), ' ')
    return if($act eq string($result)) then ()
      else concat('Serialized result ''', $act, ''' not equal to ''', $result, '''.')
  } catch * {
    concat('Serialized comparison to ''', $result, ''' failed with: [',
      $err:code, '] ', $err:description)
  }
};

(:~
 : Checks if the result is a permutation of the result of the given expression.
 : @param $eval implementation-dependent function for dynamic XQuery evaluation
 : @param $res result to be checked
 : @param $result expected result
 : @result possibly empty sequence of error descriptions
 :)
declare function check:assert-permutation(
  $eval   as function(xs:string) as item()*,
  $res    as item()*,
  $result as element()
) {
  try {
    let $exp := $eval($result)
    return if(check:unordered($res, $exp)) then ()
      else concat('Result isn''t a permutation of ''', $result, '''.')
  } catch * {
    concat('Unordered comparison to ', $result, ' failed with: [',
      $err:code, '] ', $err:description)
  }
};

(:~
 : Helper function for unordered comparison of two sequences of items.
 : @param $xs first sequence
 : @param $ys second sequence
 : @return true() if the second sequence is a permutation of the first,
 :   false() otherwise
 :)
declare function check:unordered(
  $xs as item()*,
  $ys as item()*
) as xs:boolean {
  if(empty($xs)) then empty($ys)
  else
    let $i := check:index-of($ys, head($xs), 1)
    return exists($i)
       and check:unordered(tail($xs), remove($ys, $i))
};

(:~
 : Finds the index of the first item in a sequence that's deep-equal to a given
 : item.
 : @param $xs sequence
 : @param $x item to be found
 : @$i current index
 : @param index of item if found, empty sequence otherwise
 :)
declare function check:index-of(
  $xs as item()*,
  $x  as item(),
  $i  as xs:integer
) as xs:integer? {
  if(empty($xs)) then ()
  else if(deep-equal($x, head($xs))) then $i
  else check:index-of(tail($xs), $x, $i + 1)
};

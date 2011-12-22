(:~
 : Start script of the XQuery driver for the QT3 Test Suite.
 :
 : @author BaseX Team 2005-11, BSD License
 : @author Leo Wörteler
 : @version 0.1
 :)
import module namespace fots = "http://www.w3.org/2010/09/qt-fots-catalog"
  at 'fots.xqm';

(:~ Path to the test suite files. :)
declare variable $path as xs:string external := "../";

(:~
 : Predicate function for excluding tests with unsupported dependencies.
 : @param $dep   - dependency name
 : @param $value - dependency string value
 : @return <code>true()</code> if the test should be skipped,
 :   <code>false()</code> otherwise
 :)
declare function local:exclude(
  $dep as xs:string,
  $val as xs:string
) as xs:boolean {
  let $map := map{
      'feature':='namespace-axis',
      'xml-version':='1.1',
      'language':='de'
    }
  return $map($dep) = $val
    or $dep eq 'format-integer-sequence'
      and (
        try {
          empty(util:eval(concat('format-integer(1, "', $val, '")')))
        } catch * {
          true()
        }
      )
};

(:~
 : Evaluation function (implementation-specific).
 : @param $query - query to be executed
 : @return evaluation result
 :)
declare function local:eval(
  $query as xs:string
) as item()* {
  util:eval(replace($query, '&#xD;', '&amp;#xD;'))
};

fots:run(
  local:eval#1,
  $path,
  local:exclude#2
)

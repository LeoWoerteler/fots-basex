(:~
 : A copy function as demanded by the QT3 test suite.
 :
 : @author BaseX Team 2005-11, BSD License
 : @author Leo Wörteler
 : @version 0.1
 :)
module namespace fots = "http://www.w3.org/2010/09/qt-fots-catalog";

(:~
 : Creates a copy of the given XML node.
 : @param $nd node to be copied
 : @return copy of <code>$nd</code>
 :)
declare function fots:copy(
  $nd as node()
) as node() {
  typeswitch($nd)
    case document-node()
      return document { map(fots:copy#1, $nd/(* | text())) }
    case element()
      return element { node-name($nd) }
        { map(fots:copy#1, $nd/(@* | * | text())) }
    case attribute()
      return attribute { node-name($nd) } { $nd/data() }
    case processing-instruction()
      return processing-instruction { node-name($nd) } { $nd/data() }
    case comment()
      return comment { $nd/data() }
    case text()
      return text { $nd/data() }
    default return error(xs:QName('fots:FOTS9999'),
      concat('Unknown node: ', serialize($nd)))
};

module namespace env = "http://www.w3.org/2010/09/qt-fots-catalog/environment";

declare namespace fots = "http://www.w3.org/2010/09/qt-fots-catalog";

declare function env:envs(
  $env as element(fots:environment)?,
  $envs as element(fots:environment)*
) as element()* {
  let $ref := $env/@ref
  return (if($ref) then env:envs($envs[@name eq $ref], $envs) else (), $env/*)
};

declare function env:environment(
  $env as element(fots:environment)?,
  $envs as element(fots:environment)*
) as map(xs:string, item()*) {
  fold-left(env:build#2, map{}, env:envs($env, $envs))
};

declare function env:build(
  $map as map(xs:string, item()*),
  $env as element()
) as  map(xs:string, item()*) {
  let $name := local-name($env)
  return env:insert(
    $map, $name,
    switch($name)
      case 'namespace' return
        map:new((
          $map($name),
          map{$env/@prefix := xs:anyURI($env/@uri/data())}
        ))
      case 'static-base-uri' return xs:anyURI($env/@uri/data())
      case 'collation' return
        (xs:anyURI($env/@uri/data()), $env/@default = 'true')
      case 'collection' return
        map:new((
          $map($name),
          map{$env/@uri := $env/*}
        ))
      case 'function' return ($map($name), xs:string($env/@name))
      case 'function-library' return
        map:new((
          $map($name),
          map{$env/@name := xs:string($env/@xquery-location)}
        ))
      case 'source' return xs:string($env/@file)
      case 'decimal-format' return
        map:new((
          $map($name),
          map{normalize-space($env/@name) := 
            map:new(
              for $att in $env/@*
              let $name := local-name($att)
              where $name ne 'name'
              return map:entry($name, xs:string($att))
            )
          }
        ))
      default return trace(serialize($env), $name)
  )
};

declare function env:keys($map as map(*)?) as item()* {
  if(exists($map)) then map:keys($map) else ()
};

declare function env:insert(
  $map as map(*),
  $key as xs:anyAtomicType,
  $value as item()*
) as map(*) {
  map:new(($map, map:entry($key, $value)))
};

declare function env:prolog(
  $map as map(*),
  $path as xs:string,
  $sub as xs:string
) {
  string-join(
    (
      let $base-uri := $map('static-base-uri')
      return concat('declare base-uri "',
        if(exists($base-uri)) then $base-uri else concat($path, $sub),
        '";'),

      let $ns := $map('namespace')
      for $k in env:keys($ns)
      return concat('declare namespace ', $k, ' = "', $ns($k), '";'),

      let $lib := $map('function-library')
      for $k in env:keys($lib)
      return concat('import module namespace "', $k, '" at "', $lib($k), '";'),

      let $funs := $map('function')
      return if($funs = 'fots:copy')
        then concat(
          'import module namespace fots',
          ' = "http://www.w3.org/2010/09/qt-fots-catalog"',
          ' at "fots-copy.xqm";'
        ) else (),

      let $coll := $map('collation')
      where exists($coll) and $coll[2]
      return concat("declare default collation '", $coll[1], "';"),

      let $source := $map('source')
      where exists($source)
      return concat("declare context item := doc('",
        if(file:exists(concat($path, $source)))
          then $path else concat($path, $sub),
      $source, "');"),

      let $dfs := $map('decimal-format')
      for $k in env:keys($dfs)
      let $decl := if($k eq '')
                   then 'default decimal-format'
                   else concat('decimal-format ', $k)
      return concat('declare ', $decl, ' ',
        string-join(
          let $df := $dfs($k)
          for $k2 in map:keys($df)
          return concat($k2, '="', $df($k2), '"')
        , ' ')
      , ';')
    ), '&#xa;'
  )
};


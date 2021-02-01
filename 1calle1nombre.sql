SELECT
  results."ine:municipio" AS id
  , results.name
  , current_date AS date
  , results.incomplete
  , results.total
  , round( 1-( results.incomplete::NUMERIC / results.total ) , 2 ) AS percentage
FROM
  (
    SELECT
      municipios."ine:municipio"
      , municipios.name
      , sum(CASE WHEN (pol.highway IN ('residential', 'living_street', 'pedestrian') AND pol.name IS NULL AND pol.noname IS NULL) THEN 1 ELSE 0 END) AS incomplete
      , count(*) AS total
    FROM
      planet_osm_line pol
      , (
        SELECT
          name
          , way
          , "ine:municipio"
        FROM
          planet_osm_polygon
        WHERE
          admin_level = '8'
          AND boundary = 'administrative'
          AND (
            :REGION = ''
            OR St_within(
              way
              , (
                SELECT
                  way
                FROM
                  planet_osm_polygon pop
                WHERE
                  boundary = 'administrative'
                  AND admin_level IN (
                    '4', '6'
                  )
                  AND (
                    (
                      length(:REGION) > 2
                      AND unaccent(name) ~* :REGION
                    )
                    OR "ISO3166-2" = 'ES-' || :REGION
                  )
              )
            )
          )
      ) AS municipios
    WHERE
      ST_Within(
        pol.way
        , municipios.way
      )
    GROUP BY
      municipios."ine:municipio"
      , municipios.name
  ) AS results

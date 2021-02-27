SELECT
  results."ine:municipio" AS id
  , results.name
  , current_date AS date
  , results.incomplete
  , results.total
  , CASE WHEN results.total = 0 THEN 1 ELSE round( 1-( results.incomplete::NUMERIC / results.total ) , 2 ) END AS percentage
  , round(results.length_incomplete::NUMERIC, 2) AS length_incomplete
  , round(results.length_total::NUMERIC, 2) AS length_total
  , CASE WHEN results.length_total = 0 THEN 1 ELSE round((1-( results.length_incomplete / results.length_total ))::NUMERIC, 2) END AS length_percentage
FROM
  (
    SELECT
      municipios."ine:municipio"
      , municipios.name
      , sum(CASE WHEN (pol.highway IN ('residential', 'living_street', 'pedestrian') AND pol.name IS NULL AND pol.noname IS NULL) THEN 1 ELSE 0 END) AS incomplete
      , sum(CASE WHEN (pol.highway IN ('residential', 'living_street', 'pedestrian')) THEN 1 ELSE 0 END) AS total
      , sum(CASE WHEN (pol.highway IN ('residential', 'living_street', 'pedestrian') AND pol.name IS NULL AND pol.noname IS NULL) THEN st_length(pol.way, true) ELSE 0 END) AS length_incomplete
      , sum(CASE WHEN (pol.highway IN ('residential', 'living_street', 'pedestrian')) THEN st_length(pol.way, true) ELSE 0 END) AS length_total
    FROM
      planet_osm_line pol
      , (
        SELECT
          name
          , way
          , COALESCE("ine:municipio", osm_id::TEXT) AS "ine:municipio"
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
                    OR "ISO3166-2" = 'ES-' || upper(:REGION)
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

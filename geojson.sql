SELECT
  jsonb_build_object(
    'type', 'FeatureCollection',
    'features', jsonb_agg(features.feature)
  )
FROM
  (
    SELECT
      jsonb_build_object(
        'type', 'Feature',
        'geometry', st_asgeojson( ST_Simplify( municipios.way , 0.001, TRUE ) , 3 )::jsonb,
        'properties', jsonb_build_object(
          'id', municipios."ine:municipio",
          'name', municipios.name
        )
      ) AS feature
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
      , municipios.way
  ) AS features

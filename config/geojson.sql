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
        'geometry', st_asgeojson( ST_Simplify( divisiones.way , 0.001, TRUE ) , 3 )::jsonb,
        'properties', jsonb_build_object(
          'id', divisiones.id,
          'name', divisiones.name
        )
      ) AS feature
    FROM
      planet_osm_line pol
      , (
          SELECT
            coalesce("ine:municipio", "ISO3166-2") AS id
            , name
            , way
          FROM
            planet_osm_polygon
          WHERE
            admin_level = (
              CASE
                WHEN lower(:LEVEL) = 'ccaa' THEN '4'
                WHEN lower(:LEVEL) = 'prov' THEN '6'
                ELSE '8'
              END
            )
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
      ) AS divisiones
    WHERE
      ST_Within(
        pol.way
        , divisiones.way
      )
    GROUP BY
      divisiones.id
      , divisiones.name
      , divisiones.way
  ) AS features

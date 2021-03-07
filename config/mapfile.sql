WITH prov AS (
  SELECT
    "ISO3166-2" AS id
    , way
  FROM
    planet_osm_polygon pop
  WHERE
    boundary = 'administrative'
    AND admin_level = '6'
)
, ccaa AS (
  SELECT
    "ISO3166-2" AS id
    , way
  FROM
    planet_osm_polygon pop
  WHERE
    boundary = 'administrative'
    AND admin_level = '4'
)
SELECT
  COALESCE( "ine:municipio" , osm_id::TEXT ) AS id
  , prov.id AS prov
  , ccaa.id AS ccaa
  , name
FROM
  planet_osm_polygon pop
INNER JOIN prov ON
  st_within(
    pop.way
    , prov.way
  )
INNER JOIN ccaa ON
  st_within(
    pop.way
    , ccaa.way
  )
WHERE
  boundary = 'administrative'
  AND admin_level = '8'
  AND (
    :REGION = ''
    OR St_within(
      pop.way
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
              LENGTH( :REGION ) > 2
              AND unaccent(name) ~* :REGION
            )
            OR "ISO3166-2" = 'ES-' || upper(:REGION)
          )
      )
    )
  )
ORDER BY
  1

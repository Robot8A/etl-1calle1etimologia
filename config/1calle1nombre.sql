WITH municipios AS (
  SELECT
    name
    , way
    , COALESCE("ine:municipio", osm_id::TEXT) AS id
  FROM
    planet_osm_polygon pop
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
)
, prov AS (
  SELECT
    "ISO3166-2" AS id
    , way
  FROM
    planet_osm_polygon
  WHERE
    admin_level = '6'
    AND boundary = 'administrative'
)
, ccaa AS (
  SELECT
    "ISO3166-2" AS id
    , way
  FROM
    planet_osm_polygon
  WHERE
    admin_level = '4'
    AND boundary = 'administrative'
)
, streets AS (
  SELECT
    *
  FROM
    planet_osm_line
  WHERE
    highway IN (
      'residential', 'living_street', 'pedestrian'
    )
    AND junction IS NULL
)
, results AS (
  SELECT
    municipios.id AS id
    , prov.id AS prov
    , ccaa.id AS ccaa
    , municipios.name
    , sum(CASE WHEN (streets.way IS NOT NULL AND streets.name IS NULL AND streets.noname IS NULL) THEN 1 ELSE 0 END) AS incomplete
    , sum(CASE WHEN (streets.way IS NOT NULL) THEN 1 ELSE 0 END) AS total
    , sum(CASE WHEN (streets.way IS NOT NULL AND streets.name IS NULL AND streets.noname IS NULL) THEN st_length(streets.way, TRUE) ELSE 0 END) AS length_incomplete
    , sum(CASE WHEN (streets.way IS NOT NULL) THEN st_length(streets.way, TRUE) ELSE 0 END) AS length_total
  FROM
    streets
  RIGHT JOIN municipios ON
    st_within(
      streets.way
      , municipios.way
    )
  LEFT JOIN prov ON
    st_within(
      municipios.way
      , prov.way
    )
  LEFT JOIN ccaa ON
    st_within(
      municipios.way
      , ccaa.way
    )
  GROUP BY
    municipios.id
    , municipios.name
    , prov.id
    , ccaa.id
)
SELECT
  results.id
  , results.prov
  , results.ccaa
  , results.name
  , to_char(current_date, 'YYYY-MM-01') AS date
  , results.incomplete
  , results.total
  ,
  CASE
    WHEN results.total = 0 THEN 1
    ELSE round( 1-( results.incomplete::NUMERIC / results.total ) , 2 )
  END AS percentage
  , round(results.length_incomplete::NUMERIC, 2) AS length_incomplete
  , round(results.length_total::NUMERIC, 2) AS length_total
  ,
  CASE
    WHEN results.length_total = 0 THEN 1
    ELSE round((1-( results.length_incomplete / results.length_total ))::NUMERIC, 2)
  END AS length_percentage
FROM
  results
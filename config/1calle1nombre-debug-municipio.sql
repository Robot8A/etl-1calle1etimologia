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
    AND lower(name) ~* lower(:MUNICIPIO)
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
)
SELECT
  municipios.id AS id
  , municipios.name
  , streets.osm_id
  , streets.way
FROM
  streets
RIGHT JOIN municipios ON
  st_within(
    streets.way
    , municipios.way
  )
WHERE 
 streets.name IS NULL AND streets.noname IS NULL

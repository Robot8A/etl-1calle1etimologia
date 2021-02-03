## Introducción 
`etl-1calle1nombre` es un generador de informes CSV y ficheros GeoJSON para el proyecto **#1calle1nombre**.
La fuente original de datos es https://download.geofabrik.de/europe/spain.html

## Requisitos

- [osm2pgsql](https://osm2pgsql.org/doc/install.html) transformará el fichero _.pbf_ descargado de Geofabrik. Es necesario tener una [base de datos postgres](https://osm2pgsql.org/doc/manual.html#preparing-the-database) instalada.
- [nodejs](https://nodejs.org/en/) (opcional, solo para _merge_) utilizará la herramienta `npx` para ejecutar [mapshaper](https://github.com/mbloch/mapshaper) que es quién unirá en un fichero geográfico (topojson) los datos CSV con los GeoJSON. 

## Herramientas
Ejecutar los distintos comandos desde el directorio raíz.

#### **bin/updatedb**
Encargado de descargarse los datos de Geofabrik y ejecutar _osm2pgsql_. Por defecto la base de datos es `osm` y el usuario con el que se ejecuta es el nombre de tu propio usuario.

#### **bin/report <location>**
Generador de informes CSV en la carpeta `reports/<YYYYMM>/<location>.csv`, donde `YYYYMM` es una carpeta con un nombre de tipo fecha en dicho formato; y `location` es el nombre del parámetro que hayamos puesto.

Acepta un parámetro de entrada `location` para generar el informe específico de un sitio. Si se ejecuta sin parámetros el informe se crea para todo el país (`ES`). Este parámetro puede ser los dos digitos identificativos del código __ISO3166-2__ de la provincia/comunidad o su __nombre__, también acepta __ccaa__ y __prov__ como atajos para todas las comunidades y todas las provincias, respectivamente.

```sh
$ bin/report ccaa                   # Informes para cada CCAA: AN.csv, AR.csv, AS.csv...
$ bin/report AS CL CT               # Informes para Asturias, Castilla y León y Catalunya
$ bin/report badajoz "La rioja"     # Informes para badajoz y la rioja: badajoz.csv, "La rioja.csv"
$ bin/report cádiz SEVILLA M        # Informes para Cádiz, Sevilla y Madrid: cádiz.csv, SEVILLA.csv, M.csv
```

#### **bin/feature <location>**
Generador de ficheros GeoJSON en la carpeta `features/<location>.geojson`, donde `location` es el nombre del parámetro que hayamos puesto.

Funciona de igual manera que `bin/report`: acepta un parámetro de entrada `location` para generar el informe específico de un sitio. Si se ejecuta sin parámetros el informe se crea para todo el país (`ES`). Este parámetro puede ser los dos digitos identificativos del código __ISO3166-2__ de la provincia/comunidad o su __nombre__, también acepta __ccaa__ y __prov__ como atajos para todas las comunidades y todas las provincias, respectivamente.

```sh
$ bin/feature prov                   # GeoJSONs para cada provincia: A.geojson, AB.geojson, AL.geojson...
$ bin/feature RI lugo                # GeoJSONs para La Rioja y lugo: RI.geojson, lugo.geojson
```

#### **bin/merge <location>**
Genera un fichero [TopoJSON](https://github.com/topojson/topojson-specification/blob/master/README.md) con todos los CSV de las carpetas de `reports/*` a partir del GeoJSON especificado. El archivo se crea en la carpeta inicial del proyecto con el nombre elegido en `location`

Funciona de igual manera que los precedentes scripts, pero es __importante__ tener en cuenta que el `location` escogido debe ser el mismo del CSV, como del GeoJSON. Es decir, si ejecutamos:
```sh
$ bin/merge CL
```
ha de existir previamente un fichero `features/CL.geojson` y al menos un informe llamado `CL` en `reports/*/CL.csv`. Por tanto se recomienda ejecutar previamente los comandos `report` y `feature`.

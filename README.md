## Introducción 
`etl-1calle1nombre` es un generador de informes CSV y ficheros GeoJSON para el proyecto **#1calle1nombre**.
La fuente original de datos es https://download.geofabrik.de/europe/spain.html y https://download.geofabrik.de/africa/canary-islands.html

## Requisitos

- [osmium-tool](https://osmcode.org/osmium-tool/) unirá en un solo fichero _.pbf_ los datos descargados de Geofabrik (_spain_ + _canary-islands_)
- [osm2pgsql](https://osm2pgsql.org/doc/install.html) insertará el _.pbf_ del paso anterior en la base de datos. Es necesario tener una [base de datos postgres](https://osm2pgsql.org/doc/manual.html#preparing-the-database) instalada, con su correspondiente extensión [PostGIS](https://postgis.net/).
- [nodejs](https://nodejs.org/en/) (opcional, solo para _merge_) utilizará la herramienta `npx` para ejecutar [mapshaper](https://github.com/mbloch/mapshaper) que es quién unirá en un fichero geográfico (topojson) los datos CSV con los GeoJSON. 

## Herramientas
Ejecutar los distintos comandos desde el directorio raíz.

#### **bin/updatedb**
Encargado de descargarse los datos de Geofabrik y ejecutar _osm2pgsql_. Por defecto la base de datos es `osm` y el usuario con el que se ejecuta es el nombre de tu propio usuario.

#### **bin/report _location_**
Generador de informes CSV en la carpeta `reports/<YYYYMM>/<location>.csv`, donde `YYYYMM` es una carpeta con un nombre de tipo fecha en dicho formato; y `location` es el nombre del parámetro que hayamos puesto.

Acepta un parámetro de entrada `location` para generar el informe específico de un sitio. Si se ejecuta sin parámetros el informe se crea para todo el país (`ES`). Este parámetro puede ser los dos digitos identificativos del código __ISO3166-2__ de la provincia/comunidad o su __nombre__, también acepta __ccaa__ y __prov__ como atajos para todas las comunidades y todas las provincias, respectivamente.

```sh
$ bin/report ccaa                   # Informes para cada CCAA: AN.csv, AR.csv, AS.csv...
$ bin/report AS CL CT               # Informes para Asturias, Castilla y León y Catalunya
$ bin/report badajoz "La rioja"     # Informes para badajoz y la rioja: badajoz.csv, "La rioja.csv"
$ bin/report cádiz SEVILLA M        # Informes para Cádiz, Sevilla y Madrid: cádiz.csv, SEVILLA.csv, M.csv
```

#### **bin/feature [-a|--admin _admin_level_] [-t|--tolerance _tolerance_] _location_**
Generador de ficheros GeoJSON en la carpeta `features/<location>.<admin>.geojson`, donde `location` es el nombre del parámetro que hayamos puesto, y `admin`, el nivel administativo, que por defecto es __municipios__. Opcionalmente, se puede especificar el nivel de agrupación `--admin` y el detalle `--tolerance` de la feature generada.

Funciona de igual manera que `bin/report`: acepta un parámetro de entrada `location` para generar el informe específico de un sitio. Si se ejecuta sin parámetros el informe se crea para todo el país (`ES`). Este parámetro puede ser los dos digitos identificativos del código __ISO3166-2__ de la provincia/comunidad o su __nombre__, también acepta __ccaa__ y __prov__ como atajos para todas las comunidades y todas las provincias, respectivamente.

La opción `-a`, o también `--admin`, sirve para agrupar el parámetro de entrada según se indique. Si no se especifica, el archivo resultante esta dividido por municipios. Acepta __ccaa__ y __prov__, los cuales dividirán la entrada en comunidad autónoma o provincia.

La opción `-a`, o también `--tolerance`, especifica el nivel de detalle del GeoJSON. Corresponde con la función __ST_Simplify__ de PostGIS. Acepta valores entre 0 y 1, donde _1_ es mínimo nivel de detalle. Por defecto es de _0.001_.

```sh
$ bin/feature prov                 # Divisiones municipales cada provincia: A.municipios.geojson, AB.municipios.geojson...
$ bin/feature RI lugo              # Divisiones municipales para La Rioja y lugo: RI.municipios.geojson, lugo.municipios.geojson
$ bin/feature -a ccaa              # Divisiones de comunidad para cada CCAA: AS.ccaa.geojson, AN.ccaa.geojson...
$ bin/feature -t 0.01 -a prov VA   # Divisiones provinciales para Valladolid con un detalle menor: VA.prov.geojson
```

#### **bin/merge -r|--reports _csv_ -g|--feature _feature_ [-f|--format _format_] [-n|--name _name_]**
Genera un fichero [TopoJSON](https://github.com/topojson/topojson-specification/blob/master/README.md) a partir de uno (o varios) CSV y el GeoJSON que se especifique. El archivo _1calle1nombre.json_ resultante se crea en la carpeta raíz del proyecto. Este comando utiliza _node_ para ejecutar la herramienta [mapshaper](https://mapshaper.org/).

Los parámetros `-r`, también se puede escribir `--reports`, y `-f`, o `--feature` en su versión larga, son obligatorios; donde `csv` es la ruta de archivo CSV (se pueden usar asteriscos para indicar más de un elemento, envolviendo el argumento entre comillas) y `feature` la ruta del GeoJSON en concreto. El parámetro `-f` o `--format` es opcional, si queremos el resultado en topojson o geojson (por defecto, topojson). Por último, el parámetro opcional `-n` o `--name` para cambiar el nombre al archivo resultante, que por defecto es _1calle1nombre.json_

```sh
$ bin/merge -r reports/202001/CL.csv -g features/CL.geojson       # Output en TopoJSON
$ bin/merge -r "reports/*/GL.csv" -g features/GL.geojson -f geojson  # Output en GeoJSON con datos de todos los csv
$ bin/merge -r "reports/*/GL.csv" -g features/GL.geojson -n GL.json  # Fichero resultante GL.json en formato TopoJSON
```
La unión de archivos se produce a través del campo `id` presente tanto en los _reports_ como las _features_, correspondiente al código INE del municipio. Por tanto, aplicar unos csv a un geojson de una región diferente, no producirá el resultado esperado.

Actualmente se ejecuta una transformación de los datos del informe, agrupando cada `date` y `percentage` en una propiedad llamada `values`, y dejando `id` y `name` tal cual. Es decir, un objeto `properties` de la forma:
```json
{
  "id": "05154",
  "name": "Navadijos",
  "values": {
    "2020-01-01": 0,
    "2020-11-01": 0.52,
    "2020-12-01": 0.52,
    "2021-01-01": 0.52,
    "2021-02-03": 0.52
  }
}
```

#### **bin/mapfile _location_**
Generador de ficheros CSV en la carpeta `mapfiles/<location>.mapfile.csv`, que contienen un mapa de claves de los municipios (o entidades) dentro de la localización. Útil para editar o actualizar antiguos informes.

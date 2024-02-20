# xlsx2owl

Using a spreadsheet to collect concepts for an ontology benefits from the high number of users interacting with spreadsheet software everyday.
With *xlsx2owl* domain experts can add and edit concepts in a special spreadsheet structure.
The spreadsheet can easily get translated to a turtle coded owl file with the YARRRML/RML mapping and shell script contained.

![conversion process](doc/xlsx2owl-overview.drawio.svg)


## Usage

usage information as printed with `--help` option:

```
usage:
xlsx2owl.sh [options] [download-url]

positional parameters:
  [download-url]:
            optional url from where the spreadsheet gets downloaded.
            Take local input file if no download-url is given.
            needs to start with a protocoll (e.g. https://...),
            supported protocolls are http, https and file.
named parameters:
  -h, --help:
            produces this usage info and exits.
  -d, --debug :
            enable debug output
  -y, --yarrrml <FILE> :
            path <FILE> to the yarrrml mapping file to use.
            defaults to 'yarrrml.yml' in the scripts directory.
  -o, --outputPrefix <PREFIX> :
            set prefix <PREFIX> for the generated output.
            default 'rdf-out', relativ to the current working directory.
  -i, --input <FILE> :
            path <FILE> to the input spreadsheet file to use
            or where to store spreadfile downloaded.
            default 'xlsx2owl-tmp.xlsx'
  --noPreprocess :
            skip csv preprocessing.
            Otherwise we add row number, file, sheet, current date and xlsx2owl version
            as metadata columns to CSV files.
  --test <FILE>:
            enable test mode, use <FILE> as expected result ttl file to diff against.
            In test mode the current time value is fixed to '2024-01-01T00:00:00+00:00'.
```

### run as docker container

* build docker image:
  * either manual via `$ buildah bud -t xlsx2owl ./`
  * or with nextflow via `
* run xlsx2owl with docker image on `xlsx2owl-Example.xlsx` in current directory e.g. via `$ podman run -it --rm -v "./:/data/" xlsx2owl-sd --input '/data/xlsx2owl-Example.xlsx'`

### run test

* run docker image with test input e.g. via `$ podman run -it --rm -v "./test:/data/" xlsx2owl --debug -o /data/test-out 'file:///data/test-input.xlsx'`


## Dependencies

* [YARRRML parser](https://github.com/RMLio/yarrrml-parser)
* [RMLMapper](https://github.com/RMLio/rmlmapper-java)
* [xlsx2csv](https://github.com/dilshod/xlsx2csv)
* curl
* Python 3 (for xlsx2csv)
* Java 17 (for RMLMapper)
* node.js 20 (for YARRRML)
* bash >=5 (for bash regex support)
* getopt from unix-utils (for argument parsing)


## History

* Version 2.2.0 (2024-02-20):
  * added additional metadata
  * added static csv columns (row number, sheetname, date, ...) as additional mapping input (disable with parameter --noPreprocess)
  * added option --test to automate basic testing by comparing computed result to expected result
* Version 2.1.1 (2023-11-09):
  * fixed unintended rendering of (foreign) prefixed subjects of classes, relations or attributes
  * fixed Dockerfile bash install
  * updated to SeMiFuLi 0.2.1(adds 'contains' function), RML-Mapper 6.2.2, xlsx2csv 0.8.1+(from 11/2023)
  * updated Dockerfile to java 21(from eclipse temurin), nodejs 21, yarrrml@v1.6.1
  * switched Dockerfile to node:21-alpine for reduced dockerfile and faster build
  * minor fixes in xlsx2owl.sh
  * switched GitLab-CI container build process to kaniko
* Version 2.0 (2023-07-24)
  * rename script from xlsx2owl-StahlDigital.sh to xlsx2owl.sh
  * updated to RML-Mapper 6.2.1, SeMiFuLi 0.2, java 17
  * updated Dockerfile to debian 11, java 17, nodejs 20.
  * added resources/prefixes.csv to Dockerfile
* Version 1.0 (2023-05-05)
  * first public version


## Acknowledgement

We want to kindly thank [Sebastian Tramp](https://github.com/seebi) and [eccenca GmbH](https://eccenca.com) for the initial idea, spreadsheet structure and rich input.

Work for this has been funded by the German Federal Ministry of Education and Research under grant number 13XP5116B.


## License

This project is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.

# xlsx2owl

Using a spreadsheet to collect concepts for an ontology benefits from the high number of users interacting with spreadsheet software everyday.
With *xlsx2owl Stahl* domain experts can add and edit concepts in a special spreadsheet structure.
The spreadsheet can easily get translated to a turtle coded owl file with the YARRRML/RML mapping and shell script contained.

![conversion process](doc/xlsx2owl-overview.drawio.svg)

## Usage

usage information as printed with `--help` option:
```
usage:
xlsx2owl-StahlDigital.sh [options] [download-url]

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
            default 'xlst-out', relativ to the current working directory.
  -i, --input <FILE> :
            path <FILE> to the input spreadsheet file to use
            or where to store spreadfile downloaded.
            default 'xlsx2owl-tmp.xlsx'
```

### run as docker container
* build docker image, e.g. via `$ buildah bud -t xlsx2owl-sd ./`
* switch to working directory
* run docker image, e.g. via `$ podman run -it --rm -v "./:/data/" xlsx2owl-sd --input '/home/user/xlsx2owl-Example.xlsx'`
* run docker image with test input e.g. via `$ podman run -it --rm -v "./test:/data/" xlsx2owl-sd:test --debug -o test-o
ut 'file:///data/test-input.xlsx'`

## Dependencies

* Python 3 (from xlsx2csv)
* Java 1.8 (from RML)
* node.js 14 (from YARRRML)
* bash >=5 (maybe from bash regex)
* getopt from unix-utils

## Acknowledgement
used tools:
* YARRRML
* RML
* xlsx2csv
* curl

We want to kindly thank [Sebastian Tramp](https://github.com/seebi) and [eccenca GmbH](https://eccenca.com) for the initial idea, spreadsheet structure and rich input.
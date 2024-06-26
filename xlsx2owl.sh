#!/bin/bash

###
# License header:
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
###

###
# Requirements:
# * Bash (with regexp support)
# * getopt (from linux-utils)
# * curl (for download)
# * python3 (>=3.4 according to xlsx2csv)
# * Java 17 (for rmlmapper)
# * Javascript (for yarrrml-parser, e.g. node.js version 20)
# * yarrrml-parser at ~/node_modules/@rmlio/yarrrml-parser (e.g. via `npm i -g @rmlio/yarrrml-parser`)
###

VERSION="2.2.1"
echo "xlsx2owl Version ${VERSION}"

###
# init bash options
###
set -o nounset # print out error on usage of unset variable
set -o errexit # exit on any error
# as errexit makes it difficult to get result code from failing commands, use e.g. "cat /tmp/doesnotexist && rc=$? || rc=$?"
# see https://stackoverflow.com/questions/9629710/what-is-the-proper-way-to-detect-shell-exit-code-when-errexit-option-is-set#15844901
set -o pipefail # exit on failed pipe commands


############
############
## initialization and parameter parsing
############
############

###
# define some variables
###
# directory that should contain a tool directory
optScriptDir="$(dirname "${0}")"
# work directory
optWorkFolder="./"
# tool directory
optToolFolder="${optScriptDir}/tools"
# resources directory
optResourcesFolder="${optScriptDir}/resources"
# input xlsx filename, used as download target filename as well if download specified
optXlsxFilename="xlsx2owl-tmp.xlsx"
# YARRRML filename
optYarrrmlFilename="yarrrml.yml"
# csv tmp folder
optCsvFolder="${optWorkFolder}csv"
# output Prefix
optOutputFilenamePrefix="rdf-out"
# url for downloading spreadsheet
unset optDownloadUrl
# current datetime string
optDateTime="$(date -u -Iseconds)"
# debug mode
optDebug=false
# disable preprocessing mode
optPreprocess=true
# enable test mode
optTest=false


###
# define options and help message
###

printUsage() {
cat <<EOF
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
            default 'rdf-out', relativ to the current working directory.
  -i, --input <FILE> :
            path <FILE> to the input spreadsheet file to use
            or where to store spreadfile if download url is given.
            default 'xlsx2owl-tmp.xlsx'
  --noPreprocess :
            skip csv preprocessing.
            Otherwise additional metadata columns get added to CSV files:
            "xlsx2owl_rowNumber", "xlsx2owl_filename", "xlsx2owl_sheetname",
            "xlsx2owl_datetime", "xlsx2owl_version"
  --test <FILE>:
            enable test mode, use <FILE> as expected result ttl file to diff against.
            In test mode the current time value is fixed to '2024-01-01T00:00:00+00:00'.
EOF
}

# added '+' at short option string to enable the positional parameter
LONGOPTS=help,debug,yarrrml:,outputPrefix:,input:,noPreprocess,test:
OPTIONS=+hdy:o:i:

###
# check a modern version of getopt from unix-utils is present
###
! getopt --test > /dev/null 
if [[ ${PIPESTATUS[0]} -ne 4 ]]; then
    echo '`getopt --test` failed in this environment.' >> /dev/stderr
    exit 1
fi


###
# prepare parameters using getopt from unix-util as suggested at https://stackoverflow.com/a/29754866
###
# use ! and $PIPESTATUS[0] because of "set -o errexit"
! PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTS --name "$0" -- "$@")
if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
    # e.g. return value is 1
    #  then getopt has complained about wrong arguments to stdout
    echo "error parsing parameters" >> /dev/stderr
    printUsage
    exit 2
fi
eval set -- "$PARSED"

###
# iterate over named parameters passed
while true; do
    case "$1" in
        -h|--help)
            printUsage
            exit 0
            ;;
        -d|--debug)
            optDebug=true
            shift
            ;;
        -y|--yarrrml)
            optYarrrmlFullFilepath="$2"
            shift 2
            ;;
        -o|--outputPrefix)
            optOutputFilenamePrefix="$2"
            shift 2
            ;;
        -i|--input)
            optXlsxFilename="$2"
            shift 2
            ;;
        --noPreprocess)
            optPreprocess=false
            shift
            ;;
        --test)
            optTest="$2"
            optDateTime="2024-01-01T00:00:00+00:00"
            echo "test mode enabled, fixed current time value to ${optDateTime}"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error" >> /dev/stderr
            exit 3
            ;;
    esac
done

###
# define some more variables 
###
optYarrrmlFullFilepath="${optYarrrmlFullFilepath:=${optScriptDir}/${optYarrrmlFilename}}"
optRmlFullFilepath="${optYarrrmlFullFilepath}.ttl"


###
# read in download url parameter if present
###
if [[ $# -eq 1 ]]
then
    ## checking url format
    ## should start with http or https or file and not contain one of { ";'}:
    if [[ "${1}" =~ ^(https?|file):\/\/[^\ \"\;\']+$ ]]
    then
        optDownloadUrl="${1}"
    else
        echo "unexpected url format (file,http or https supported): '$*'" >> /dev/stderr
        printUsage
        exit 4
    fi
elif [[ $# -ne 0 ]]
then
    echo "to many parameters: '$*'" >> /dev/stderr
    printUsage
    exit 5
fi

###
# print debug output
###
if [[ "${optDebug}" = true ]]
then
    echo "variable values:"
    set | grep ^opt
    echo
fi


############
############
## download and prepare input files, run mapping
############
############

###
# download if url given
###
if [[ -n ${optDownloadUrl:-} ]] # expand variable because of "set -o nounset"
then
## download file
    echo "downloading spreadsheet from '${1}'"
    curl -L --cookie cookie "${1}" --output "${optXlsxFilename}"
    inputFileName="${optXlsxFilename:-$(basename ${1} | cut -d'?' -f1)}"
else
    inputFileName="${optXlsxFilename}"
fi

###
# create csv input files
###
echo "converting xlsx to csv"
python3 "${optToolFolder}/xlsx2csv.py" --all "${optXlsxFilename}" "${optCsvFolder}"
if [[ "${optPreprocess}" = true ]]
then
    for file in "${optCsvFolder}"/*.csv; do
        echo "preprocessing $file ..."
        sheetName="$(basename "${file}" .csv)"
        python3 "${optToolFolder}/csvColumnAdder.py" --rowNumberHeader "xlsx2owl_rowNumber" "$file" "xlsx2owl_filename" "${inputFileName}" "xlsx2owl_sheetname" "${sheetName}" "xlsx2owl_datetime" "${optDateTime}" "xlsx2owl_version" "${VERSION}"
    done
fi


###
# create RML mapping file from yarrrml
###
echo "create rml rules from yarrrml"
echo "  yarrrml version $(~/node_modules/@rmlio/yarrrml-parser/bin/parser.js --version || true)"
~/node_modules/@rmlio/yarrrml-parser/bin/parser.js --version
~/node_modules/@rmlio/yarrrml-parser/bin/parser.js --pretty -i "${optYarrrmlFullFilepath}" -o "${optRmlFullFilepath}"
RC=$?
if [[ "${optDebug}" = true ]]
then
    echo "  RC=$RC"
fi

###
# create graph as turtle and nquads
###
runMapper() {
    paramType="${1}"
    paramSuffix="${2}"
    targetFilename="${optOutputFilenamePrefix}.${paramSuffix}"
    metadataFilename="${optOutputFilenamePrefix}.meta.${paramSuffix}"
    
    debugParameter=""
    if [[ "${optDebug}" = true ]]
    then
        debugParameter="--verbose"
    fi
    echo -n "  ${paramType}..."
    IRI_PREFIX_MAP_FILE="${optCsvFolder}/prefixes.csv" java -jar "-DIRI_PREFIX_MAP_FILE=${optCsvFolder}/prefixes.csv" "${optToolFolder}/rmlmapper.jar" --mappingfile "${optRmlFullFilepath}" --duplicates --functionfile "${optResourcesFolder}/functions_xlsx2owl.ttl" --functionfile "${optResourcesFolder}/functions_grel.ttl" --functionfile "${optResourcesFolder}/grel_java_mapping.ttl" --serialization "${paramType}" --outputfile "${targetFilename}" --metadataDetailLevel dataset --metadatafile "${metadataFilename}" ${debugParameter}
    RC=$?
    if [[ "${optDebug}" = true ]]
    then
      echo -n "RC=$RC "
    fi
    echo "${targetFilename}"
}
echo "create graph as turtle and nquads..."
echo "rmlmapper version"; unzip -p "${optToolFolder}/rmlmapper.jar" "META-INF/maven/be.ugent.rml/rmlmapper/pom.properties" | grep -E "version=|artifactId="
runMapper turtle ttl
runMapper nquads nq

###
# output statistics (triples=lines in nquad serialization
###
echo -n "triples( == nquad lines) generated:"
wc -l "${optOutputFilenamePrefix}.nq"

if [[ "${optTest}" != false ]]
then
    echo "diffing against test file"
    EXIT_CODE=0
    diff "${optTest}" "${optOutputFilenamePrefix}.ttl" || EXIT_CODE=$?
    if [[ $EXIT_CODE -eq 0 ]]
    then
        echo "diff test passed"
    else
        echo "diff test failed" >> /dev/stderr
        exit 1
    fi  
fi

#\bin\bash

###
# Requirements:
# * Bash (with regexp support)
# * getopt (from linux-utils)
# * curl (for download
# * python3 (>=3.4 according to xlsx2csv)
# * Java 8 (for rmlmapper)
# * Javascript (for yarrrml-parser)
# * yarrrml-parser at ~/node_modules/@rmlio/yarrrml-parser (e.g. via `npm i -g @rmlio/yarrrml-parser`)
###

###
# define some variables
###
# directory that should contain a tool directory
optScriptDir="$(dirname "${0}")"
# work directory
optWorkFolder="./"
# tool directory
optToolFolder=${optScriptDir}/tools
# input xlsx filename, used as download target filename as well if download specified
optXlsxFilename="xlsx2owl-StahlDigital.xlsx"
# YARRRML filename
optYarrrmlFilename="yarrrml.yml"
# csv tmp folder
optCsvFolder="${optWorkFolder}/csv"
# output Prefix
optOutputFilenamePrefix="StahlDigital-vocab"
# url for downloading spreadsheet
unset optDownloadUrl
optDebug=true

###
# parse options
###
printUsage() {
    echo "'xlsx2owl-StahlDigital.sh [download-url-starting-with-http]'"
}

if [[ $# -eq 1 ]]
then
    ## checking url
    ## should start with http or https and not contain one of { ";'}:
    if [[ "${1}" =~ ^https?:\/\/[^\ \"\;\']+$ ]]
    then
        optDownloadUrl="${1}"
    else
        echo "unexpected url format: '$*'"
        printUsage
        exit 1
    fi
    
elif [[ $# -eq 0 ]]
then
    true
    # using local spreadsheet
else
    echo "unexpected parameters: '$*'"
    printUsage
    exit 1
fi

###
# print debug output
###
if [[ "${optDebug}" = true ]]
then
    echo "variable values:"
    set | grep ^opt
fi

###
# process
###

## download if url given
if [[ -n ${optDownloadUrl} ]]
then
## download file
    echo "downloading spreadsheet from '${1}'"
    curl "${1}" --output "${optXlsxFilename}"
fi

## create csv
echo "converting xlsx to csv"
python3 "${optToolFolder}/xlsx2csv.py" --all "${optXlsxFilename}" "${optCsvFolder}"

## create rml from yarrrml
echo "create rml rules from yarrrml"
echo "  yarrrml version $(~/node_modules/@rmlio/yarrrml-parser/bin/parser.js --version || true)"
~/node_modules/@rmlio/yarrrml-parser/bin/parser.js --version
~/node_modules/@rmlio/yarrrml-parser/bin/parser.js --pretty -i "${optScriptDir}/${optYarrrmlFilename}" -o "${optWorkFolder}/${optYarrrmlFilename}.ttl"

## create graph as turtle and nquads
runMapper() {
    paramType=${1}
    paramSuffix=${2}
    targetFilename="${optOutputFilenamePrefix}.${paramSuffix}"
    echo -n "  ${paramType}..."
    java -jar "${optToolFolder}/rmlmapper.jar" --mappingfile "${optWorkFolder}/${optYarrrmlFilename}.ttl" --duplicates --functionfile "${optScriptDir}/resources/functions_xlsx2owl.ttl" --serialization "${paramType}" --outputfile "${targetFilename}"
    echo "${targetFilename}"
}
echo "create graph as turtle and nquads..."
runMapper turtle ttl
runMapper nquads nq
# podman run --rm -v "$(pwd):/home/rmluser/data" yarrrmlmapper "${$optYarrrmlFilename}" --use-local-rml-mapper --duplicates --functionfile resources/functions_xlsx2owl.ttl --serialization turtle --outputfile "${optOutputFilenamePrefix}.ttl"
#podman run --rm -v "$(pwd):/home/rmluser/data" yarrrmlmapper "${$optYarrrmlFilename}" --use-local-rml-mapper --duplicates --functionfile resources/functions_xlsx2owl.ttl --serialization nquads --outputfile "${optOutputFilenamePrefix}.nq"

## count lines
echo "triples( == nquad lines) generated:"
wc --lines "${optOutputFilenamePrefix}.nq"
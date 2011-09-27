#! /bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
# mother.sh
#
#   Invokes the UI Automation tests using the Mother-May-UI javascript test
#   framework.
#
# Example(s):
#
#   $ ./mother.sh -i 1341234124
#                 -a Sample.app \
#                 -o outputDir 
#                 -v
#                 testFile.js
# 
# Discussion:
#
#   This shell script invokes `instruments' so that the supplied UI Automation
#   tests can be run against the device identified by the UDID (specified as
#   the argument to -i) is available from the Xcode's Organizer.  If the -i 
#   option is specified and the device is plugged in, this script will run 
#   the tests using the referenced device. If it is not supplied, this script 
#   will run the tests using the simulator. 
#
#   You can specify the path to the app, however, the specified app must
#   be able to be run on the specified device.  If you only give the name of 
#   the app (as in Sample.app), this script will attempt to find it.  If you 
#   specif a UDID, this script will attempt to find the app in the current
#   user's Xcode build directory.  In particular, the following directory 
#   will be sought out:
#
#     ~/Library/Developer/Xcode/DerivedData/.../Debug-iphoneos/Sample.app
#
#   If there are multiple app bundles that match the value of the -a 
#   argument, the most recently touched one will be used.  This behavior
#   does not occur when you explicitly name the app bundle to use.
#
#   The results of this script end up in the output directory under a 
#   timestamped subdirectory.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Fail on any error
set -e

app=""
deviceID=""
outputDir=""
targetApp=""
traceTemplate=""
command="instruments"
verbose=0
testFile=""
dateTime=$(date +%Y-%m-%dT%H.%M.%S)
usage="Usage: ${0} -i <device ID> -a <app bundle> -o <output dir> [-v] <test file>"

function lastModifiedTime {
  dir=${1}
  echo $(find "${1}" -exec stat -f "%m" \{} \; | sort -n -r | head -1)
}


# Options

while getopts ":a:i:t:o:v" opt
do
  case ${opt} in
    a)
      app=${OPTARG}
      ;;
    i)
      deviceID=${OPTARG}
      ;;
    o)
      outputDir="${OPTARG}/${dateTime}"
      ;;
    v)
      verbose=1
      ;;
    ?)
      echo "${usage}"
      exit 1
  esac
done

shift $(($OPTIND - 1))

if [[ -z "${app}" || -z "${outputDir}" ]]
then
  echo "${usage}"
  exit 1
fi


# Device ID

if [[ ! -z "${deviceID}" ]]
then
  command="${command} -w \"${deviceID}\""
fi


# Trace Template

traceTemplate=$(find /Developer/Platforms/iPhoneOS.platform/Developer/Library/Instruments -type f -name "Automation.tracetemplate")

if [[ -z "${traceTemplate}" ]]
then
  echo "Error: Could not find Automation.tracetemplate" >&2
  exit 1
else
  command="${command} -t \"${traceTemplate}\""
fi


# Target App

if [[ -d ${app} ]]
then
  targetApp=${app}
else
  mostRecentlyModifiedTime=-1
  environment=""

  if [[ -z "${deviceID}" ]]
  then
    environment="iphonesimulator"
  else
    environment="iphoneos"
  fi

  for potentialApp in $(find ~/Library/Developer/Xcode/DerivedData -type d -path "*/Build/Products/Debug-${environment}/${app}")
  do
    if [[ "${modifiedTime}" == -1 ]]
    then
      mostRecentlyModifiedTime=$(lastModifiedTime ${potentialApp})
      targetApp=${potentialApp}
    fi

    modifiedTime=$(lastModifiedTime ${potentialApp})

    if [[ ${modifiedTime} > ${mostRecentlyModifiedTime} ]]
    then
      mostRecentlyModifiedTime=${modifiedTime}
      targetApp=${potentialApp}
    fi
  done
fi

if [[ -z "${targetApp}" ]]
then
  echo "Error: Could not find ${app}" >&2
  exit 1
else
  command="${command} ${targetApp}"
fi


# Output Directory

if [[ ! -d "${outputDir}" ]]
then
  mkdir -p "${outputDir}"
fi

command="${command} -e UIARESULTSPATH \"${outputDir}\""


# Trace Document
# instruments doesn't currently seem to respect this

command="${command} -d \"${outputDir}/mother.trace\""


# Test File

if [[ -z "$*" ]]
then
  echo "Error: No test scripts were given"
  exit 1
else
  for scriptFile in "$*"
  do
    if [[ -f "${scriptFile}" ]]
    then
      testFile=$(find "${PWD}" -name "${scriptFile}")
    else
      echo "Error: Could not find ${scriptFile}"
      exit 1
    fi
  done

  command="${command} -e UIASCRIPT \"${testFile}\""
fi

if (( ${verbose} > 0))
then
  echo "${command}"
fi


# Workaround the output trace file by just changing to the output directory so any output ends up in there

pushd . > /dev/null
tempOutputDir="${outputDir}/tmp-$$"
mkdir "${tempOutputDir}" > /dev/null
pushd "${tempOutputDir}" > /dev/null

eval ${command} || exit 1

for tempTraceDocument in $(ls ${tempOutputDir})
do
  targetAppName=$(basename ${targetApp})
  finalTraceDocument="${outputDir}/${targetAppName}.trace"
  mv "${tempTraceDocument}" "${finalTraceDocument}"
done

rm -rf "${tempOutputDir}"

# Restore the working directory

popd > /dev/null

echo "Results are located in ${outputDir}"

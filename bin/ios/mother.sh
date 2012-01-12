#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# mother.sh
#
#   Invokes the UI Automation tests using the Mother May UI JavaScript test
#   framework.
#
# Example(s):
#
#   $ ./mother.sh -w 1341234124
#                 -a Sample.app
#                 -o outputDir
#                 -t testFile.js
#                 -i
#                 -v
# 
# Discussion:
#
#   This shell script invokes `instruments' so that the supplied UI Automation
#   tests can be run against the device identified by the UDID (specified as the
#   argument to -w) is available from the Xcode's Organizer.  If the -w option
#   is specified and the device is plugged in, this script will run the tests
#   using the referenced device. If it is not supplied, this script will run the
#   tests using the simulator.
#
#   You can specify the path to the app, however, the specified app must be able
#   to be run on the specified device.  If you only give the name of the app (as
#   in Sample.app), this script will attempt to find it.  If you specif a UDID,
#   this script will attempt to find the app in the current user's Xcode build
#   directory.  In particular, the following directory will be sought out:
#
#     ~/Library/Developer/Xcode/DerivedData/.../Debug-iphoneos/Sample.app
#
#   If there are multiple app bundles that match the value of the -a argument,
#   the most recently touched one will be used.  This behavior does not occur
#   when you explicitly name the app bundle to use.
#
#   The results of this script end up in the output directory under a
#   timestamped subdirectory.
#   
#   Enabling the Inspect option (-i argument) will automatically open the 
#   resulting trace document in Instruments.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Bash params
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Fail on any error
set -e
# Debug output
#set -x


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Global Variables
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

app=""
deviceID=""
outputDir=""
targetApp=""
traceTemplate=""
command="instruments"
verbose=0
inspect=0
testFile=""
dateTime=$(date +%Y-%m-%dT%H.%M.%S)
usage="Usage: ${0} -w <device ID> -a <app bundle> -o <output dir> -t <test file> [-i -v]"


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Functions
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function getAbsolutePath {
  dir=$(dirname "$1")
  cd "$dir"
  absolutePath="$(pwd)"/"$(basename "$1")"
  cd - >/dev/null
  echo $absolutePath
}

function parseOptions {
  while getopts ":a:w:t:o:iv" opt
  do
    case ${opt} in
      a)
        app=${OPTARG}
        ;;
      t)
        testFile=${OPTARG}
        ;;
      w)
        deviceID=${OPTARG}
        ;;
      o)
        outputDir="${OPTARG}/${dateTime}"
        ;;
      i)
        inspect=1
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
}

function setDeviceId {
  if [[ ! -z "${deviceID}" ]]
  then
    command="${command} -w \"${deviceID}\""
  fi
}

function setTraceTemplate {
  # Finds the default Automation trace template file.
  traceTemplate=$(find /Developer/Platforms/iPhoneOS.platform/Developer/Library/Instruments -type f -name "Automation.tracetemplate")
  if [[ -z "${traceTemplate}" ]]
  then
    echo "Error: Could not find Automation.tracetemplate" >&2
    exit 1
  else
    command="${command} -t \"${traceTemplate}\""
  fi
}

function setTargetApp {
  # If the app is a full directory path, then use the directory path as is
  if [[ -d ${app} ]]
  then
    targetApp="${app}"
  # The location of the app is unknown. Finds the path.
  else
    # Path differs for Simulator or Device
    environment=""
    if [[ -z "${deviceID}" ]]
    then
      environment="iphonesimulator"
    else
      environment="iphoneos"
    fi

    # Finds the most recent version of the app
    targetApp=$(find ~/Library/Developer/Xcode/DerivedData -type d -path "*/Build/Products/Debug-${environment}/${app}" -ls \
      | sort -M -k8,10 \
      | tr -s " " \
      | cut -d" " -f 11-)
  fi

  if [[ -z "${targetApp}" ]]
  then
    echo "Error: Could not find ${app}" >&2
    exit 1
  else
    command="${command} \"${targetApp}\""
  fi
}

function setOutputDirectory {
  if [[ ! -d "${outputDir}" ]]
  then
    mkdir -p "${outputDir}"
  fi

  outputDir="$(getAbsolutePath "${outputDir}")"
  command="${command} -e UIARESULTSPATH \"${outputDir}\""
}

function setTestFile {
  if [[ -f "${testFile}" ]]
  then
    testFile=$(getAbsolutePath "${testFile}")
    command="${command} -e UIASCRIPT \"${testFile}\""
    echo "${command}"
  else
    echo "Error: No test script was given"
    exit 1
  fi
}

function runTest {
  # Not sure how to specify the output directory for instruments (the -d param
  # does not seem to work), so executing the instruments command from the output
  # directory.
  tempOutputDir="${outputDir}/tmp-$$"
  mkdir "${tempOutputDir}"
  cd "${tempOutputDir}"

  # Executes the test
  eval ${command} || exit 1

  # Moves all the trace documents to given specified output directory
  for tempTraceDocument in $(ls "${tempOutputDir}")
  do
    targetAppName=$(basename "${targetApp}")
    finalTraceDocument="${outputDir}/${targetAppName}.trace"
    mv "${tempTraceDocument}" "${finalTraceDocument}"
    if (( ${inspect} > 0 ))
    then
        open "${finalTraceDocument}"
    fi
  done

  # Cleans up
  rm -rf "${tempOutputDir}"

  # Restore the working directory
  cd - >/dev/null
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Run the Test
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# Parses the options
parseOptions "$@"

# Builds up the instruments command
setDeviceId
setTraceTemplate
setTargetApp
setOutputDirectory
setTestFile

# Prints out the built up command if in verbose mode
if (( ${verbose} > 0))
then
  echo "${command}"
fi

# Executes the test
runTest


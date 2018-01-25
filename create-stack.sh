#!/bin/sh
# 
# Simple shell script to run a CloudFormation template with a set of parameters and tags
#

Usage () {
  cat <<EOF
$0 profile directory name [other arguments]

This will create a cloudformation stack named "name" which uses the main.yaml CloudFormation template in
the directory "directory" unless a "name.yaml" exists in that directory.  In addition it will look in the 
"directory/settings" subdirectory for parameters and tags of the form:

directory/settings/name-parameters.json
directory/settings/name-tags.json

EOF
  exit
}

debug=
if [ "x$1" = "x-d" ]; then
  debug=echo
  shift
fi

if [ "$#" -lt 3 ]; then
  Usage
fi

profile="$1"
shift
directory="$1"
shift
name="$1"
shift

ARGS="$@"

# figure out the stack to run
if [ -f "${directory}/${name}.yaml" ]; then
  ARGS="$ARGS --template-body file://${directory}/${name}.yaml "
elif [ -f "${directory}/main.yaml" ]; then
  ARGS="$ARGS --template-body file://${directory}/main.yaml "
else
  echo "No main template found in that directory"
  Usage
fi

# figure out the parameter file to use
if [ -f"${directory}/settings/${name}-parameters.json" ]; then
  ARGS="$ARGS --parameters file://${directory}/settings/${name}-parameters.json "
elif [ -f "${directory}/settings/main-parameters.json" ]; then
  ARGS="$ARGS --parameters file://${directory}/settings/main-parameters.json "
else
  echo "No parameters were found in the settings subdirectory"
  Usage
fi

# figure out the tags file to use
if [ -f "${directory}/settings/${name}-tags.json" ]; then
  ARGS="$ARGS --tags file://${directory}/settings/${name}-tags.json "
elif [ -f "${directory}/settings/main-parameters.json" ]; then
  ARGS="$ARGS --tags file://${directory}/settings/main-tags.json "
else
  echo "# Skipping tags since none were found"
fi

$debug exec aws --profile "$profile" cloudformation create-stack --stack-name "$name" $ARGS
exit

#!/bin/sh
# 
# Simple shell script to run a CloudFormation template with a set of parameters and tags
#

Usage () {
  cat <<EOF
$0 template [other arguments]

This will validate a cloudformation template file named "template" (or "template/main.yaml" if template is a 
directory).  On successful completion it will dump a json display of the parameters in the template.

EOF
  exit
}

debug=
if [ "x$1" = "x-d" ]; then
  debug=echo
  shift
fi

if [ "$#" -lt 1 ]; then
  Usage
fi

template="$1"
shift

ARGS="$@"

# figure out the stack to validate
if [ -d "${template}" ]; then
  ARGS="$ARGS --template-body file://${template}/main.yaml "
elif [ -f "${template}" ]; then
  ARGS="$ARGS --template-body file://${template} "
else
  echo "No template found."
  exit
fi

$debug exec aws cloudformation validate-template $ARGS
exit

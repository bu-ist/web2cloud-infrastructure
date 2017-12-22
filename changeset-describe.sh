#!/bin/sh
# 
# Simple shell script to run a CloudFormation template with a set of parameters and tags
#

Usage () {
  cat <<EOF
$0 profile directory stackname changesetname [other arguments]

This will describe a change set named "changename" for the cloudformation stack named "stackname" in the account
"profile."  It only has the "directory" parameter to be consistent with other commands.

EOF
  exit
}

debug=
if [ "x$1" = "x-d" ]; then
  debug=echo
  shift
fi

if [ "$#" -lt 4 ]; then
  Usage
fi

profile="$1"
shift
directory="$1"
shift
name="$1"
shift
changename="$1"
shift

ARGS="$@"

$debug exec aws --profile "$profile" --output text cloudformation describe-change-set \
  --stack-name "$name" --change-set-name "$changename" $ARGS
exit

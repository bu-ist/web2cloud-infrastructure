#!/bin/bash
#
# Shell script to request an ACM certificate for a host (and a bunch of subject alternative names
# with DNS validation.  
#

request_cert_dns () {
  domain="$1"
  shift

  TMPFILE="/tmp/cert.$$"
  ARN=$(aws --profile w2c-non-prod --output text acm request-certificate --domain-name "$domain" --validation-method DNS --subject-alternative-names "*.$domain")
  echo "ARN=$ARN" 
  # save the certificate details in a temp file
  sleep 5
  aws --profile w2c-non-prod acm --output json describe-certificate --certificate-arn "$ARN" >"$TMPFILE"
  echo "tempfile name= $TMPFILE"
  cat $TMPFILE
  # now we go through the details to get the DNS entry to make
  TYPE=$(jq '.Certificate.DomainValidationOptions[].ResourceRecord.Type' <"$TMPFILE")
  VALUE=$(jq '.Certificate.DomainValidationOptions[].ResourceRecord.Value' <"$TMPFILE")
  NAME=$(jq '.Certificate.DomainValidationOptions[].ResourceRecord.Name' <"$TMPFILE")

  echo $NAME $TYPE $VALUE

  rm "$TMPFILE"
}

request_cert_dns "$@"

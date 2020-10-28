#!/bin/sh -x
#
# Shell script to set up Shibboleth for AWS account.
#
# Select TEST or PROD Shib at SHIB_IDP variable below.
#
# Shibboleth-rolename
# 
# For example, Shibboleth-powerUserAccess which has the PowerUserAccess managed policy
#
# For the above the Identity Provider must be named Shibboleth
#
# The other end of the authentication process uses special eduPersonEntitlements which the 
# Shibboleth IdP maps to the above entrys.
#
# So the eduPersonEntitlement http://iam.bu.edu/sp/amazon-187621470568-powerUserAccess
# will be mapped to the following ARN values:
#
# arn:aws:iam::187621470568:saml-provider/Shibboleth (for logging in)
# arn:aws:iam::187621470568:role/Shibboleth-powerUserAccess
#
# If there are more than one roles AWS will ask which one to use.
#
# Once the IdP is configured one can start the AWS Shibboleth authentication by going to:
#
# https://shib.bu.edu/idp/profile/SAML2/Unsolicited/SSO?providerId=urn:amazon:webservices
#
# Create Provider ->
# Type: SAML
# Name: Shibboleth
# Metadata document: shib.bu.edu or shib-test.bu.edu
#
#

SHIB_NAME=Shibboleth
#SHIB_IDP=https://shib.bu.edu/idp/shibboleth
SHIB_IDP=https://shib-test.bu.edu/idp/shibboleth

PROFILE="$1"
if [ "x$PROFILE" = "x" ]; then
  PROFILE=default
fi

# ####
# see if we already have the Shibboleth provider set up
#
if aws --output text --profile "$PROFILE" iam list-saml-providers | grep -q "$SHIB_NAME" ; then
  echo "Already configured SAML metadata"
else
  echo "Need to add SAML provider"
  tmp_file="/tmp/shib_setup-$$.xml"

  # ####
  # Download the metadata
  #
  curl -o "$tmp_file" "$SHIB_IDP"

  if [ -f "$tmp_file" ]; then
    aws --profile "$PROFILE" iam create-saml-provider \
      --saml-metadata-document "file://$tmp_file" --name "$SHIB_NAME"
  fi

  echo rm "$tmp_file"
fi

# 

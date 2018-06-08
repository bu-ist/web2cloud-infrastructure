#!/bin/sh
#
# Shell script to set up Shibboleth for AWS account.
#
# By default it does the production shibboleth (shib.bu.edu)
#
# Shibboleth-rolename
# 
# For example, Shibboleth-powerUserAccess which has the PowerUserAccess managed policy
#
# For the above the Identity Provider must be named Shibboleth
#
# Create Provider ->
# Type: SAML
# Name: Shibboleth
# Metadata document: shib.bu.edu or shib-test.bu.edu
#

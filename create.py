#!/usr/bin/python3

# Simple wrapper for various AWS stack commands.  Use --help for usage.

import sys
import argparse
import re
from pathlib import Path
import os
import subprocess
import io
import json
import time
from datetime import datetime

#
# Wait for something to complete by periodically asking status (and printing it out so you know what is happening)
#
def run_cloudformation(cmdstring="", wait=False):
    # Run the given command and optionally wait until describe-stacks shows COMPLETE
    result = subprocess.run(cmdstring, stdout=subprocess.PIPE, shell=True, universal_newlines=True)
    command_output = ''
    for output in result.stdout:
        command_output += output
    print(command_output)
    if (result.returncode != 0):
        return result.returncode
        
    if not wait:
        return 0

    if (command_output == ''):
        return 0

    # Manual wait with status on command output based on the StackId returned in the JSON output
    aws_output = json.loads(command_output)
    if (not aws_output['StackId']):
        print("No StackId found in output, cannot --wait for stack to complete")
        return 1

    # Query status of stack until we get a COMPLETE output..
    check_command = "aws cloudformation describe-stacks --stack-name '{}'".format(aws_output['StackId'])
    print(check_command)
    StackStatus=''
    while (True):
        result = subprocess.run(check_command, stdout=subprocess.PIPE, shell=True, universal_newlines=True)
        command_output = ''
        for output in result.stdout:
            command_output += output
        aws_output = json.loads(command_output)
        StackStatus = aws_output['Stacks'][0]['StackStatus']
        print("{} StackStatus = {}".format(datetime.now().strftime('%Y-%m-%d %H:%M:%S'),StackStatus))
        # Stack status as per https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-cfn-describing-stacks.html#w2ab1c15c15c17c11
        if (re.search('_COMPLETE$',StackStatus)):
            break
        time.sleep(10)

    return 0

#
# Wait using the CloudFormation wait command (blocks at Amazon)
#
def wait_aws(waitstring="", command="", stackname=""):
    print()
    print("Waiting until {} on {} finishes...".format(command, stackname))
    print(waitstring)
    os.system(waitstring)
    print()

#
# Figure out how we were invoked - create, update or delete?
#
command = 'create-stack'
wait_command = 'stack-create-complete'
if (re.search('update',os.path.basename(__file__))):
    command = 'update-stack'
    wait_command = 'stack-update-complete'
if (re.search('delete',os.path.basename(__file__))):
    command = 'delete-stack'
    wait_command = 'stack-delete-complete'

parser = argparse.ArgumentParser(description='Maintain various stacks at AWS. Handy wrapper to the aws commands for creating, updating and deleting stacks.')
if command != 'delete-stack':
    parser.add_argument('--template', type=argparse.FileType('r'), help='Stack template (if not specified assumes main.yaml in $CWD or parent)')
    parser.add_argument('--iam', action='store_true',              help='Use IAM security credentials')
parser.add_argument('JSONfile', nargs=1, type=argparse.FileType('r'), help='JSON parameters file for overriding template')
parser.add_argument('--profile', type=str, default='default',         help='AWS profile to use')
parser.add_argument('--stackname', type=str,                          help='Name of stack, normally determined from JSON filename but can override here')
parser.add_argument('--region',   type=str, default='us-east-1',      help='Region to create in (%(default)s)')
parser.add_argument('--extra', type=str, default='',                  help='Misc extra args to pass to aws commands', metavar="'EXTRA ARGS'")
parser.add_argument('--noop', action='store_true',                    help='Do not run commands, just show what would do')
parser.add_argument('--wait', action='store_true',                    help='Use describe-stacks to get status and wait for stack completing')
parser.add_argument('--wait-only', action='store_true',               help='Do not run commands, only wait until a stack operation is complete')

# Pull in args and set variables.
args = parser.parse_args()

JSONfile = args.JSONfile[0]
profile = args.profile
if command != 'delete-stack':
    template=args.template
    iam = args.iam
else:
    template = ''
    iam = False
stackname = args.stackname
region = args.region
extra = args.extra
noop = args.noop
wait = args.wait
wait_only = args.wait_only

#
# Figure out the path of the template main.yaml if not overridden.
# Defaults to main.yaml in the path where the JSON file lives.
#

if (template == None):
    dirbase=''
    # Walk the path of the JSON file path.
    for dirname in Path(JSONfile.name).parts:
        dirbase=dirbase+dirname+'/'
#        print("checking {}main.yaml".format(dirbase))
        if (Path(dirbase+"main.yaml").is_file()):
            print("Defaulting --template "+dirbase+"main.yaml")
            template = dirbase+"main.yaml"
            break
# If no main.yaml found, indicate 
if (template == None):
    print("\nUnable to determine template, no main.yaml found in path of JSON file.  Override with --template if necessary...")
    exit(1)

#
# Default the stack name to substring of JSONfile filename - {stackname}-parameters.json
#
if (stackname == None):
    m = re.search(r'([\w-]+)-parameters.json',JSONfile.name)
    if (m.group(1)):
            stackname=m.group(1)

if (stackname == None):
    print("\nUnable to determine stackname from JSON filename ({}).  Filename should be stackname-parameters.json.  Override with --stackname if necessary...".format(JSONfile.name))
    exit(1)

if (iam == False):
    iam = ''
else:
    iam = "--capabilities CAPABILITY_IAM"

if command != 'delete-stack':
    cmdstring = "aws cloudformation {} --profile {} --region {} --stack-name {} --template-body file://{} --parameters file://{} {} {}".format(
        command,
        profile,
        region,
        stackname,
        template,
        JSONfile.name,
        iam,
        extra
    )
else:
    cmdstring = "aws cloudformation {} --profile {} --region {} --stack-name {} {} {}".format(
        command,
        profile,
        region,
        stackname,
        template,
        extra
    )

waitstring = "aws cloudformation wait {} --profile {} --region {} --stack-name {}".format(
    wait_command,
    profile,
    region,
    stackname
)

print()
if noop:
    print('Would run (but --noop mode):')

if not wait_only:
    print(cmdstring)

if noop and wait_only:
    print(waitstring)

if wait:
    if command != 'delete-stack':
        print('Poll with "aws cloudformation describe-stacks ..." until status is COMPLETE')
    elif noop:
        print(waitstring)

# Actually run the command now
if not noop:
    if not wait_only:
        rc = run_cloudformation(cmdstring=cmdstring,wait=wait)
        if (rc != 0):
            # run_cloudformation() will have output error message, OK to just exit here.
            exit(rc)
        if wait and command == 'delete-stack':
            # delete-stack command produces no output so falling back to "aws cloudformation wait ..."
            wait_aws(waitstring=waitstring,command=command,stackname=stackname)
    elif wait_only:
        wait_aws(waitstring=waitstring,command=command,stackname=stackname)

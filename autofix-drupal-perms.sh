#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname $(realpath "${BASH_SOURCE[0]}") )" && pwd )"

deploy_user=$(stat -c '%U' .)

$SCRIPT_DIR/drupal_fix_permissions.sh -s -u=$deploy_user -f=../private -f=../private-files

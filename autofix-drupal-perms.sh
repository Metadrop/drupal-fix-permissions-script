#!/bin/bash

deploy_user=$(stat -c '%U' .)

/usr/local/bin/drupal-fix-permissions -s -u=$deploy_user -f=../private -f=../private-files

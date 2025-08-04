#!/bin/bash

set -e

echo "zipping app and ansible folder..."

mkdir -p packaged


zip -r packaged/app.zip visitor_counter_app/
zip -r packaged/ansible.zip ansible/

echo "zips created in ./packaged"
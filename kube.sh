#!/bin/bash

set -e

echo $REPO:$CIRCLE_TAG

sed -i "s/<VERSION>/$(echo $CIRCLE_TAG | cut -c 1-7)/" template/deployment.yml
sed -i "s/<REPO>/$(echo $REPO | cut -c 1-7)/" template/deployment.yml


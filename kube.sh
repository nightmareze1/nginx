#!/bin/bash

set -e

echo $REPO:$CIRCLE_TAG

sed -i "s/<VERSION>/$REPO:$CIRCLE_TAG/" template/deployment.yml

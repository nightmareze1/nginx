#!/bin/bash

set -e

sed -i "s/<VERSION>/v0.0.${env.BUILD_NUMBER}/" template/deployment.yml
sed -i "s/<REPO>/${DOCKER_HUB_USER}/" template/deployment.yml
sed -i "s/<PROJECT>/nginx/" template/deployment.yml

#!/bin/bash

set -e

echo $REPO:$CIRCLE_TAG

sed -i "s/<VERSION>/$(echo $CIRCLE_TAG | cut -c 1-7)/" template/deployment.yml
sed -i "s/<REPO>/$(echo $REPO | cut -c 1-7)/" template/deployment.yml
sed -i "s/<PROJECT>/$(echo $CIRCLE_PROJECT_REPONAME | cut -c 1-7)/" template/deployment.yml
sed -i "s/<certificate-authority-data>/$(echo $CERTIFICATE_AUTHORITY_DATA | cut -c 1-7)/" ~/.kube/config
sed -i "s/<kube-api>/$(echo $KUBE_API | cut -c 1-7)/" ~/.kube/config
sed -i "s/<client-certificate-data>/$(echo $CLIENT_CERTIFICATE_DATA | cut -c 1-7)/" ~/.kube/config
sed -i "s/<client_key_data>/$(echo $CLIENT_KEY_DATA | cut -c 1-7)/" ~/.kube/config

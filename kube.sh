#!/bin/bash

set -e
declare repo="$1" sha="$CIRCLE_SHA1" branch="$CIRCLE_BRANCH" tag="$CIRCLE_TAG"
declare repo="$1" tag="$CIRCLE_TAG"

kubectl apply -f template/deployment.yml
kubectl apply -f template/svc.yml
kubectl apply -f template/ing.yml

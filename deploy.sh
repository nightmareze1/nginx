#!/usr/bin/env bash

TAG=latest
export BUILD_NUMBER=${TAG}
for f in ./deploy/tmpl/*.yaml
do
  envsubst < $f > "./deploy/.generated/$(basename $f)"
done

kubectl apply -f ./deploy/.generated/


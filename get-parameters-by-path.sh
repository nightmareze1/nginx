#!/bin/sh

PARAMETERS=`aws ssm get-parameters-by-path --region us-east-1 --path ${1} --with-decryption`

echo $PARAMETERS
echo ${PARAMETERS} | jq -c '.Parameters' | jq -c '.[]'

for row in $(echo ${PARAMETERS} | jq -c '.Parameters' | jq -c '.[]'); do
    KEY=$(basename $(echo ${row} | jq -c '.Name'))
    VALUE=$(echo ${row} | jq -c '.Value')

    KEY=`echo ${KEY} | tr -d '"'`
    VALUE=`echo ${VALUE} | tr -d '"'`

    export ${KEY}=${VALUE}
    echo --build-arg ${KEY}="$"'{'${KEY}'}'  | tr '\n' ' ' >> vars.env
   
done

cat vars.env | awk '{ print "docker build --build-arg BUILD_NUMBER=${BUILD_NUMBER} " $0 " -t $REPOSITORY_URI:latest ."}'
cat vars.env | awk '{ print "docker build --build-arg BUILD_NUMBER=${BUILD_NUMBER} " $0 " -t $REPOSITORY_URI:latest ."}' |bash && rm -rf vars.env

#!/bin/sh

docker ps -a -q | while read cid
do
    fini=$(docker inspect $cid | grep FinishedAt | awk -F\" '{printf("%.19s", $4)}')
    diff=$(expr $(date +"%s") - $(date --date="$fini" +"%s"))    
    echo $diff
    if [ $diff -gt 86400 ]
    then
        docker rm $cid
    fi 
done

docker rmi $(docker images -a)

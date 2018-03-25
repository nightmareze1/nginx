#!/bin/bash

set -e

NS=tn
APP=nginx
ENV=stg
PRODUCT=tn
NODE_GROUP=tn


cat <<__EOF__>deploy-app.yml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: $APP
  namespace: $NS 
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  minReadySeconds: 5
  template:
    metadata:
      labels:
        app: $APP
        env: $ENV
        product: $PRODUCT
    spec:
      terminationGracePeriodSeconds: 60
      containers:
      - name: $APP
        image: vikingo/alpine:v0.0.59
        imagePullPolicy: Always
        env:
        - name: VARIABLE1
          value: "My name is Juan and I'm a variable"
        - name: VARIABLE2
          value: "My name is Lucho and I'm a variable"
        ports:
        - containerPort: 80
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          timeoutSeconds: 1
      nodeSelector:
        kops.k8s.io/instancegroup: $NODE_GROUP
      imagePullSecrets:
        - name: myregistrykey

---
apiVersion: v1
kind: Service
metadata:
  name: $APP
  namespace: $NS
  labels:
    app: $APP
    env: $ENV
    product: $PRODUCT
  annotations: { }
spec:
  ports:
  - name: http
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: $APP
    env: $ENV
    product: $PRODUCT
  type: LoadBalancer

__EOF__

echo $NS $APP $ENV $PRODUCT

kubectl apply -f deploy-app.yml

sleep 70

ELB_ADDRESS=$(kubectl get svc $APP -n $NS -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') 

ELB_NAME=$(echo $ELB_ADDRESS | cut -c 1-32)

echo $ELB_NAME

aws elb describe-load-balancers --load-balancer-name $ELB_NAME --query 'LoadBalancerDescriptions[*].Instances[*].[InstanceId]' --output text > incorrect.txt

aws ec2 describe-instances --filters Name=tag:k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup,Values=$NODE_GROUP --query  'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId]' --output text | grep running | awk '{print $3}'> correct.txt

INCORRECT=`cat incorrect.txt`

sed 's/"//g' correct.txt > correct1.txt

CORRECT=`cat correct1.txt`

aws elb deregister-instances-from-load-balancer --region us-west-2 --load-balancer-name $ELB_NAME --instances $INCORRECT

aws elb register-instances-with-load-balancer --region us-west-2 --load-balancer-name $ELB_NAME --instances $CORRECT

#!/bin/bash

set -e

NS=tn
APP=nginx
ENV=stg
PRODUCT=tn
NODE_GROUP=tn
NODE_PORT=$(kubectl get svc $APP -n $NS -o jsonpath='{.spec.ports[*].nodePort}')
CLUSTER_NAME=cluster.dev.itshellws-k8s.com

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
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: $NODE_PORT
  selector:
    app: $APP
    env: $ENV
    product: $PRODUCT

__EOF__

echo $NS $APP $ENV $PRODUCT

kubectl delete -f deploy-app.yml

echo "Eliminando ELB" ELB-$ENV-$PRODUCT  "y desatachando del Autoscaling group " $PRODUCT.$CLUSTER_NAME 

aws autoscaling detach-load-balancers --auto-scaling-group-name $PRODUCT.$CLUSTER_NAME  --load-balancer-names ELB-$ENV-$PRODUCT

aws elb delete-load-balancer --load-balancer-name ELB-$ENV-$PRODUCT



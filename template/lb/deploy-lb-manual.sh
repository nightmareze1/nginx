#!/bin/bash

set -e

NS=tn
APP=nginx
ENV=stg
PRODUCT=tn
NODE_GROUP=tn
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
  selector:
    app: $APP
    env: $ENV
    product: $PRODUCT

__EOF__

echo $NS $APP $ENV $PRODUCT

kubectl apply -f deploy-app.yml

NODE_PORT=$(kubectl get svc $APP -n $NS -o jsonpath='{.spec.ports[*].nodePort}')

echo $NODE_PORT

aws ec2 describe-instances --filters Name=tag:k8s.io/cluster-autoscaler/node-template/label/kops.k8s.io/instancegroup,Values=$NODE_GROUP --query  'Reservations[*].Instances[*].[Placement.AvailabilityZone, State.Name, InstanceId]' --output text | grep running | awk '{print $3}'> instances.txt

INSTANCES=`cat instances.txt`

rm -rf instances.txt

echo "Subnets que se van Agregar al ELB
"

aws ec2 describe-subnets --filters Name=tag:Name,Values="itshellws_"$ENV"_"$PRODUCT"_aws_pub_a" --output text |grep subnet | awk '{print $9}' > subnet.txt
aws ec2 describe-subnets --filters Name=tag:Name,Values="itshellws_"$ENV"_"$PRODUCT"_aws_pub_b" --output text |grep subnet | awk '{print $9}' >> subnet.txt
aws ec2 describe-subnets --filters Name=tag:Name,Values="itshellws_"$ENV"_"$PRODUCT"_aws_pub_c" --output text |grep subnet | awk '{print $9}' >> subnet.txt

cat subnet.txt

SUBNETS=`cat subnet.txt`

rm -rf subnet.txt

echo ""
echo "Creando ELB DNS:

"

aws elb create-load-balancer --load-balancer-name ELB-$ENV-$PRODUCT --listeners "Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=$NODE_PORT" --subnets $SUBNETS --output text 

echo "Registrando Subnets y Instancias en el ELB
"

aws elb register-instances-with-load-balancer --region us-west-2 --load-balancer-name ELB-$ENV-$PRODUCT --instances $INSTANCES

echo "Asignando Autoscaling group" $PRODUCT.$CLUSTER_NAME al ELB-$ENV-$PRODUCT
  
aws autoscaling attach-load-balancers --auto-scaling-group-name $PRODUCT.$CLUSTER_NAME --load-balancer-names ELB-$ENV-$PRODUCT


#!/bin/bash

#Levanta e prepara o minikube(eu uso)
minikube start
alias kctl="minikube kubectl --"
alias kubectl="minikube kubectl --"
minikube docker-env
eval $(minikube -p minikube docker-env)

#Constroi as imagens(Com downgrade de versão para golang:1.14.15 para v1 e v2 phusion/baseimage:0.10.2
#*Isso demora paca, ainda empomba com o analyzer, mas monta
cd ./guestbook
sudo make
cd ..

#Registra o repositório dos charts da Bitnami
helm repo add bitnami https://charts.bitnami.com/bitnami 
if[ $? ] then
    echo "Falha inserindo repositório"
    exit 1
fi

#Instala redis a partir do chart bitnami
helm upgrade redis bitnami/redis --install --values=./roger/config/values_redis.yaml

#export REDIS_PASSWORD=$(kubectl get secret --namespace default redis -o jsonpath="{.data.redis-password}" | base64 --decode)

#Instala o guestbook gerado pelo aluno
helm upgrade guestbook ./roger --install --values=./roger/config/values_guestbook.yaml --set image.tag=v1

#Expor a aplicação
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=roger,app.kubernetes.io/instance=guestbook" -o jsonpath="{.items[0].metadata.name}")
export CONTAINER_PORT=$(kubectl get pod --namespace default $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
kubectl --namespace default port-forward $POD_NAME 9000:$CONTAINER_PORT

#kubectl get secret name-of-secret -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
#!/bin/sh

printf "ca.crt:\n"
base64 ~/.minikube/ca.crt
printf "\n\n"
read -p "Press any key to get next cert..."

printf "client.crt:\n"
base64 ~/.minikube/profiles/minikube/client.crt
printf "\n\n"
read -p "Press any key to get next cert..."

printf "client.key:\n"
base64 ~/.minikube/profiles/minikube/client.key
printf "\n\n"

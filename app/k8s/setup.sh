#!/bin/bash
eksctl create cluster --name kox-cluster --region us-east-1 \
  --nodegroup-name standard-workers --node-type t3.medium \
  --nodes 2 --nodes-min 1 --nodes-max 3

eksctl utils associate-iam-oidc-provider \
  --cluster kox-cluster \
  --region us-east-1 \
  --approve

aws eks update-kubeconfig --region us-east-1 --name kox-cluster

kubectl annotate serviceaccount service-account \
  -n external-secrets \
  eks.amazonaws.com/role-arn=arn:aws:iam::902839103466:role/eks-ssa-role
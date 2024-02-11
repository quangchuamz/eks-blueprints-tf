# EKS OVERVIEW

## Context and Usage:
OIDC in Kubernetes: OIDC is an authentication layer on top of OAuth 2.0. In Kubernetes, specifically EKS, it can be used for authentication with the Kubernetes API server.

IAM Roles for Service Accounts (IRSA): In EKS, the OIDC provider is commonly used with IRSA, allowing Kubernetes service accounts to assume IAM roles and granting specific AWS permissions to pods.

Using the OIDC provider ARN, you can then set up IAM roles and policies that trust this OIDC provider, enabling you to securely grant AWS permissions to Kubernetes service accounts and, by extension, to the pods that use those service accounts. This is a common practice for managing access to AWS resources from within Kubernetes workloads running on EKS.

## Deploy pod to specific node grouop
Kubernetes' built-in features such as node labels, taints and tolerations, and node selectors. Here's how you can do it:

### Using Labels and Node Selectors
Label the Nodes: Each node group in EKS can be labeled with a unique key-value pair. AWS EKS often automatically labels nodes with their respective node group name, but you can add custom labels as needed.

Example label for a node group:
```shell
kubectl label nodes <node-name> nodegroup=group1

```
Use Node Selector in Pod Specification: In your pod specification, use a node selector to specify which node group the pod should be scheduled on.

Example pod spec with node selector:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mycontainer
    image: myimage
  nodeSelector:
    nodegroup: group1

```
### Using Taints and Tolerations
If you want more strict control, you can use taints and tolerations:

Taint the Nodes: Apply a taint to the nodes in a specific node group. This will prevent pods that do not tolerate this taint from being scheduled on these nodes.

Example taint:
```shell
kubectl taint nodes <node-name> key1=value1:NoSchedule

```
Set Tolerations in Pod Spec: In your pod spec, define tolerations that allow the pod to be scheduled onto nodes with these specific taints.

Example pod spec with toleration:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mycontainer
    image: myimage
  tolerations:
  - key: "key1"
    operator: "Equal"
    value: "value1"
    effect: "NoSchedule"
```
### Choosing the Right Method
Node Selectors are straightforward and easy to use but less flexible.
Taints and Tolerations offer more control and are ideal for scenarios where you need to ensure that certain nodes only run specific types of workloads.
By using these methods, you can effectively control the placement of pods on specific node groups in your EKS cluster based on their specifications or requirements.





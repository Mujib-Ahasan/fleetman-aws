## All about the Architecture and Kubernetes Deployment: [here](https://github.com/Mujib-Ahasan/fleetman-minikube)
</br>

# Deploy on AWS 
- First create SSH key-pair in your local machine: `ssh-keygen -t rsa -b 4096 -f <path_you_wanna_save>` </br>
**Note: Please take care of the private key, otherwise big problem :)**
- In this repo, under the IaC directory, terraform main.tf file is there. Put the public key path like:
   ```
   resource "aws_key_pair" "web_key" {
    public_key=file("<path_to_your_ssh_public_key>")
   }
   ```
- Go to the file directory and run `terraform init` command to get plugins. After that do `terraform plan` to get a visualization of your resources. Once confirmend then apply </br>
**Note: Hope you already have aws configured in your local machine, other wise you have to provide another block [provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)**
- Take a look at your state file to get a overall idea of your ec2-instance.
- Now in that IaC directory, another folder is for ansible - the configuration of the ec2-instance. Do change the inventory file: </br>
 `my-ec2-instance ansible_host=<see_terraform_output> ansible_user=ec2-user ansible_ssh_private_key_file=<path_to_your_privte_key>`
- Once you set with this, run : `ansible my-ec2-instance -i inventory -m setup` </br>
**Note: This command tests the connection and gathers the facts about target VM**
- Run: `ansible-playbook playbook.yaml -i inventory.ini` </br>
   you can see the status on your terminal, once completed.
- Once that done, you can inspect the ec2 VM for the changes previous command made. Our kubernetes project manifest files and few tools related files are downloaded. Checkout the playbook.yaml
  for more insights.
- Now create the cluster `eksctl create cluster --name <name_of_your_cluster> --nodes-min=4` </br>
  cluster creation will take around 15-20 min. </br>
**Note: For our project, number of nodes will be 4, enough for our workloads and others essential tools.**
- Once cluster created, terminal will be free. Confirm by running `kubectl get all`
- Here comes a Important step: Run the following commands: </br>
    - `eksctl utils associate-iam-oidc-provider --region=<your_region> --cluster=<name_of_your_cluster> --approve` </br>
    - `eksctl create iamserviceaccount --name ebs-csi-controller-sa --namespace kube-system --cluster <name_of_your_cluster>
       --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy --approve  --role-only  --role-name AmazonEKS_EBS_CSI_DriverRole` </br>
    - `eksctl create addon --name aws-ebs-csi-driver --cluster <name_of_your_cluster> --service-account-role-arn arn:aws:iam::$(aws sts get-caller-identity
       --query Account --output text):role/AmazonEKS_EBS_CSI_DriverRole --force` </br>
   **Note: For EKS, it is necessary to install a "driver" to enable your Kubernetes cluster to access EBS.**
- Once done, run the steps</br>
    - `kubectl apply -f worklaods.yaml`</br>
    - `kubectl apply -f service.yaml`</br>
    - `kubectl apply -f storage-aws.yaml`</br>
    - `kubectl apply -f mongo-stack.yaml`</br>
   **Note: LoadBalancer might take few moments to start up, Copy the DNS and paste in browser, should be able to see page, list and moving Vehicles.**
- Apply the EFK stack, follow the steps:</br>
     - `kubectl apply -f fluentd-config.yaml`</br>
     - `kubectl apply -f EFK_stack.yaml`</br>
  A LoadBalancer is configured for the Kibana instance. For our project it is also possible, we can configure managed ElastitSearch service by AWS. Configuring fluentd/ fluentbit was an option
 manually and Kibana with a dedicated server. But Our approach is the most easy one and fulfill the requirements.
  **Note: Once done, checkout the service, copy the url name and paste in the browser. Once again it might take few moments to start**
- Get metrics-server just local console based provisioning and autoscaling (HPA): 
      - `helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server` : This adds the repo.
      - `helm upgrade --install metrics-server metrics-server/metrics-server --namespace kube-system --set args={"--kubelet-insecure-tls"}`: install and start the metrics server.
- Applying monitoring using helm: 
   helm was downloaded using ansible in the VM. We also have `my-custom-values.yaml` to set up the loadBalancer and password. Apply the command: </br>
   `helm install <release_name> oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack -n monitoring  --create-namespace -f my-custom-values.yaml`</br>
   Do a `kubectl get all -n monitoring`, you will get the Loadbalancer for Grafana. Copy that and paste to browser, put the password and ready to play with it.

## Testing The Web Server
To Test our web server, Please Please checkout My HTTP-load-Tester [Suzi](https://github.com/Mujib-Ahasan/Suzi). </br>
Results I attached to this repo deserve a look! Please checkout that also.
## Stop The Cluster
Once you are done with experiments, delete the cluster: `eksctl delete cluster <name_of_your_cluster>` </br>
**Note: This might take around 5-7 minutes. After deleting, go to the aws management console and check**

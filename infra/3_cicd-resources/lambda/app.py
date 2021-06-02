import boto3
import yaml

code_pipeline = boto3.client("codepipeline")


def put_job_failure(job, message):
    """Notify CodePipeline of a failed job

    Args:
        job: The CodePipeline job ID
        message: A message to be logged relating to the job status

    Raises:
        Exception: Any exception thrown by .put_job_failure_result()

    """
    print("Putting job failure")
    print(message)
    code_pipeline.put_job_failure_result(
        jobId=job, failureDetails={"message": message, "type": "JobFailed"}
    )
    return 0


def put_job_success(job, message):
    """Notify CodePipeline of a successful job

    Args:
        job: The CodePipeline job ID
        message: A message to be logged relating to the job status

    Raises:
        Exception: Any exception thrown by .put_job_success_result()

    """
    print("Putting job success")
    print(message)
    code_pipeline.put_job_success_result(jobId=job)
    return 0


def handler(event, context):
    import os
    import json
    from kubernetes import client, config
    from kubernetes.client.rest import ApiException
    from pprint import pprint

    try:
        # environment variables
        job_id = event["CodePipeline.job"]["id"]
        job_data = event["CodePipeline.job"]["data"]
        user_parameters_decoded = json.loads(
            job_data["actionConfiguration"]["configuration"]["UserParameters"]
        )
        print(user_parameters_decoded)
        commit_id = str(user_parameters_decoded["commit_id"])
        cluster_name = str(user_parameters_decoded["cluster_name"])
        # not necessary as we do not yet pass artifacts from previous stage
        # artifacts = job_data["inputArtifacts"]
        aws_region = os.getenv("AWS_REGION")
        namespace = "coi"
        aws_account_id = os.getenv("AWS_ACCOUNT_ID")
        # role_arn = os.getenv("LAMBDA_ROLE_ARN")

        # set kubeconfig
        # https://stackoverflow.com/questions/54953190/amazon-eks-generate-update-kubeconfig-via-python-script
        # Set up the client
        config_file_path = os.path.join("/tmp", "config")
        eks = boto3.client("eks")

        # get cluster details
        cluster = eks.describe_cluster(name=cluster_name)
        cluster_cert = cluster["cluster"]["certificateAuthority"]["data"]
        cluster_ep = cluster["cluster"]["endpoint"]
        cluster_arn = "arn:aws:eks:ap-southeast-1:126966121768:cluster/eks-cluster"

        # build the cluster config hash
        cluster_config = {
            "apiVersion": "v1",
            "kind": "Config",
            "clusters": [
                {
                    "cluster": {
                        "server": str(cluster_ep),
                        "certificate-authority-data": str(cluster_cert),
                    },
                    "name": str(cluster_arn),
                }
            ],
            "contexts": [
                {
                    "context": {"cluster": str(cluster_arn), "user": str(cluster_arn)},
                    "name": str(cluster_arn),
                }
            ],
            "current-context": str(cluster_arn),
            "preferences": {},
            "users": [
                {
                    "name": str(cluster_arn),
                    "user": {
                        "exec": {
                            "apiVersion": "client.authentication.k8s.io/v1alpha1",
                            "command": "aws",
                            "args": [
                                "eks",
                                "get-token",
                                "--cluster-name",
                                cluster_name,
                            ],
                        }
                    },
                }
            ],
        }

        # Write in YAML.
        config_text = yaml.dump(cluster_config, default_flow_style=False)
        f = open(config_file_path, "w")
        f.write(config_text)
        f.close()

        config.load_kube_config(config_file_path)

        client.configuration.debug = True

        api_instance_appsv1 = client.AppsV1Api()
        api_instance_corev1 = client.CoreV1Api()
        # api_instance_extensionsv1beta1 = client.ExtensionsV1beta1Api()

        deployment_list = api_instance_appsv1.list_namespaced_deployment(
            namespace=namespace
        ).items

        node_type_with_networking_dict = {
            "backend": {
                "internal_port": 5000,
                "external_port": 8080,
                "internal_lb_ip": "172.20.207.97",
            },
        }

        if len(deployment_list) > 0:
            print("Updating deployments to new container images...")
            # deployment exists, so change deployment
            for node_type in node_type_with_networking_dict:
                patch_deployment_manifest = {
                    "metadata": {"name": node_type, "namespace": namespace},
                    "spec": {
                        "replicas": 1,
                        "selector": {"matchLabels": {"app": node_type}},
                        "template": {
                            "metadata": {"labels": {"app": node_type}},
                            "spec": {
                                "containers": [
                                    {
                                        "name": "{node_type}-container".format(
                                            node_type=node_type
                                        ),
                                        "image": "{aws_account_id}.dkr.ecr.{aws_region}.amazonaws.com/{node_type}-repo:{commit_id}".format(
                                            aws_account_id=aws_account_id,
                                            aws_region=aws_region,
                                            commit_id=commit_id,
                                            node_type=node_type,
                                        ),
                                    }
                                ]
                            },
                        },
                    },
                }

                api_response = api_instance_appsv1.patch_namespaced_deployment(
                    name=node_type,
                    namespace=namespace,
                    body=patch_deployment_manifest,
                    pretty=True,
                )
                pprint(api_response)
        # else:
        #     print("Creating deployments and services...")
        #     # create deployment
        #     for node_type, networking_dict in node_type_with_networking_dict.items():
        #         print("Working on {node_type}".format(node_type=node_type))
        #         print("Creating namespace")
        #         api_response = api_instance_corev1.create_namespace(
        #             client.V1Namespace(metadata=client.V1ObjectMeta(name=namespace))
        #         )
        #         pprint(api_response)
        #         deployment_manifest = {
        #             "metadata": {"name": node_type, "namespace": namespace},
        #             "spec": {
        #                 "replicas": 1,
        #                 "selector": {"matchLabels": {"app": node_type}},
        #                 "template": {
        #                     "metadata": {"labels": {"app": node_type}},
        #                     "spec": {
        #                         "containers": [
        #                             {
        #                                 "name": "{node_type}-container".format(
        #                                     node_type=node_type
        #                                 ),
        #                                 "image": "{aws_account_id}.dkr.ecr.{aws_region}.amazonaws.com/{node_type}-repo:{commit_id}".format(
        #                                     aws_account_id=aws_account_id,
        #                                     aws_region=aws_region,
        #                                     commit_id=commit_id,
        #                                     node_type=node_type,
        #                                 ),
        #                                 "ports": [
        #                                     {
        #                                         "containerPort": networking_dict[
        #                                             "internal_port"
        #                                         ]
        #                                     }
        #                                 ],
        #                                 "envFrom": [
        #                                     {
        #                                         "configMapRef": {
        #                                             "name": "{node_type}-config".format(
        #                                                 node_type=node_type
        #                                             )
        #                                         }
        #                                     }
        #                                 ],
        #                             }
        #                         ],
        #                     },
        #                 },
        #             },
        #         }
        #         print("Creating namespaced deployment")
        #         api_response = api_instance_appsv1.create_namespaced_deployment(
        #             namespace=namespace, body=deployment_manifest
        #         )
        #         pprint(api_response)
        #         service_manifest = {
        #             "metadata": {
        #                 "name": "{node_type}-balancer".format(node_type=node_type),
        #                 "namespace": namespace,
        #                 "annotations": {
        #                     "service.beta.kubernetes.io/aws-load-balancer-type": "nlb",
        #                     "service.beta.kubernetes.io/aws-load-balancer-internal": "true",
        #                 },
        #             },
        #             "spec": {
        #                 "selector": {"app": node_type},
        #                 "sessionAffinity": "None",
        #                 "ports": [
        #                     {
        #                         "port": networking_dict["external_port"],
        #                         "targetPort": networking_dict["internal_port"],
        #                     }
        #                 ],
        #                 "clusterIp": networking_dict["internal_lb_ip"],
        #                 "type": "LoadBalancer",
        #             },
        #             "waitForLoadalancer": "false",
        #         }
        #         print("Creating namespaced service")
        #         api_response = api_instance_corev1.create_namespaced_service(
        #             namespace=namespace, body=service_manifest
        #         )
        #         pprint(api_response)
        put_job_success(job_id, "Stack update complete")
    except Exception as e:
        print("Function failed due to exception.")
        print(e)
        put_job_failure(job_id, "Function exception: " + str(e))

    # effectively run following command:
    # `kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1 --record`
    # the --record flag writes executed command to kubernetes.io/change-cause.

    return "Complete."

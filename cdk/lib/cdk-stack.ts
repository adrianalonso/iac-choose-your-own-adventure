import * as cdk from "@aws-cdk/core";
import * as ec2 from "@aws-cdk/aws-ec2";
import * as ecr from "@aws-cdk/aws-ecr";
import * as ecs from "@aws-cdk/aws-ecs";
import * as logs from "@aws-cdk/aws-logs";
import * as iam from "@aws-cdk/aws-iam";
import * as elbv2 from "@aws-cdk/aws-elasticloadbalancingv2";
import * as docker from "@aws-cdk/aws-ecr-assets";

import * as path from "path";

export class MyCdkStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Crear la VPC con subredes no conflictivas
    const vpc = new ec2.Vpc(this, "MainVpc", {
      cidr: "10.0.0.0/16",
      maxAzs: 2,
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: "PublicSubnet1",
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: "PublicSubnet2",
          subnetType: ec2.SubnetType.PUBLIC,
        },
        {
          cidrMask: 24,
          name: "PrivateSubnet1",
          subnetType: ec2.SubnetType.PRIVATE_WITH_NAT,
        },
        {
          cidrMask: 24,
          name: "PrivateSubnet2",
          subnetType: ec2.SubnetType.PRIVATE_WITH_NAT,
        },
      ],
    });

    // Security Groups
    const lbSg = new ec2.SecurityGroup(this, "LoadBalancerSecurityGroup", {
      vpc,
      allowAllOutbound: true,
    });

    lbSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      "Allow HTTP inbound"
    );

    const ecsServiceSg = new ec2.SecurityGroup(
      this,
      "EcsServiceSecurityGroup",
      {
        vpc,
        allowAllOutbound: true,
      }
    );

    ecsServiceSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      "Allow HTTP inbound"
    );

    // Application Load Balancer
    const lb = new elbv2.ApplicationLoadBalancer(this, "LB", {
      vpc,
      internetFacing: true,
      securityGroup: lbSg,
      vpcSubnets: {
        subnets: vpc.selectSubnets({
          subnetType: ec2.SubnetType.PUBLIC,
          onePerAz: true,
        }).subnets,
      },
    });

    const listener = lb.addListener("Listener", {
      port: 80,
      open: true,
    });

    // ECR Repository
    const repository = new ecr.Repository(this, "Repository", {
      repositoryName: "repo",
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      imageScanOnPush: true,
    });

    // Construye y publica la imagen de Docker desde el directorio local
    const dockerImage = new docker.DockerImageAsset(this, "MyDockerImage", {
      directory: path.join(__dirname, "../app"),
      platform: docker.Platform.LINUX_AMD64,
    });

    // ECS Cluster
    const cluster = new ecs.Cluster(this, "Cluster", {
      clusterName: "cluster",
      vpc,
    });

    // CloudWatch Log Group
    const logGroup = new logs.LogGroup(this, "LogGroup", {
      logGroupName: "/fargate/service",
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    // Fargate Task Definition
    const taskDefinition = new ecs.FargateTaskDefinition(
      this,
      "TaskDefinition",
      {
        cpu: 256,
        memoryLimitMiB: 512,
      }
    );

    taskDefinition.addContainer("awsx-ecs", {
      image: ecs.ContainerImage.fromDockerImageAsset(dockerImage),
      cpu: 128,
      memoryLimitMiB: 512,
      portMappings: [{ containerPort: 80 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: "ecs", logGroup }),
    });

    // Fargate Service
    const fargateService = new ecs.FargateService(this, "Service", {
      cluster,
      taskDefinition,
      desiredCount: 1,
      securityGroups: [ecsServiceSg],
      vpcSubnets: { subnets: vpc.privateSubnets },
    });

    listener.addTargets("TargetGroup", {
      port: 80,
      targets: [fargateService],
    });

    // Permissions for CloudWatch Logs
    const executionRole = new iam.Role(this, "ExecutionRole", {
      assumedBy: new iam.ServicePrincipal("ecs-tasks.amazonaws.com"),
    });

    executionRole.addManagedPolicy(
      iam.ManagedPolicy.fromAwsManagedPolicyName(
        "service-role/AmazonECSTaskExecutionRolePolicy"
      )
    );

    logGroup.grantWrite(executionRole);

    new cdk.CfnOutput(this, "FrontendURL", { value: lb.loadBalancerDnsName });
    new cdk.CfnOutput(this, "RepositoryURL", {
      value: repository.repositoryUri,
    });
  }
}

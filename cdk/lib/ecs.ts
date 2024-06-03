import * as cdk from "@aws-cdk/core";
import * as ecs from "@aws-cdk/aws-ecs";
import * as logs from "@aws-cdk/aws-logs";
import * as ec2 from "@aws-cdk/aws-ec2";

interface EcsProps {
  vpc: ec2.Vpc;
  dockerImage: ecs.ContainerImage;
}

export class EcsStack extends cdk.Construct {
  public readonly fargateService: ecs.FargateService;
  public readonly ecsServiceSg: ec2.SecurityGroup;
  public readonly logGroup: logs.LogGroup;

  constructor(scope: cdk.Construct, id: string, props: EcsProps) {
    super(scope, id);

    this.ecsServiceSg = new ec2.SecurityGroup(this, "EcsServiceSecurityGroup", {
      vpc: props.vpc,
      allowAllOutbound: true,
    });

    this.ecsServiceSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      "Allow HTTP inbound"
    );

    this.logGroup = new logs.LogGroup(this, "LogGroup", {
      logGroupName: "/fargate/service",
      retention: logs.RetentionDays.ONE_WEEK,
      removalPolicy: cdk.RemovalPolicy.DESTROY,
    });

    const cluster = new ecs.Cluster(this, "Cluster", {
      clusterName: "cluster",
      vpc: props.vpc,
    });

    const taskDefinition = new ecs.FargateTaskDefinition(
      this,
      "TaskDefinition",
      {
        cpu: 256,
        memoryLimitMiB: 512,
      }
    );

    taskDefinition.addContainer("awsx-ecs", {
      image: props.dockerImage,
      cpu: 128,
      memoryLimitMiB: 512,
      portMappings: [{ containerPort: 80 }],
      logging: ecs.LogDrivers.awsLogs({
        streamPrefix: "ecs",
        logGroup: this.logGroup,
      }),
    });

    this.fargateService = new ecs.FargateService(this, "Service", {
      cluster,
      taskDefinition,
      desiredCount: 1,
      securityGroups: [this.ecsServiceSg],
      vpcSubnets: { subnets: props.vpc.privateSubnets },
    });
  }
}

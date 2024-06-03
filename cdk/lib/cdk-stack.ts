import * as cdk from "@aws-cdk/core";
import * as ecs from "@aws-cdk/aws-ecs";

import { NetworkStack } from "./network";
import { EcrStack } from "./ecr";
import { EcsStack } from "./ecs";
import { AlbStack } from "./loadbalancer";
import { ProjectProps } from "./interfaces";

export class CYACdkStack extends cdk.Stack {
  constructor(scope: cdk.Construct, id: string, props?: ProjectProps) {
    super(scope, id, props);

    const network = new NetworkStack(this, "NetworkStack");

    const ecr = new EcrStack(this, "EcrStack");

    const fargate = new EcsStack(this, "EcsStack", {
      vpc: network.vpc,
      dockerImage: ecs.ContainerImage.fromDockerImageAsset(ecr.dockerImage),
    });

    const alb = new AlbStack(this, "AlbStack", {
      vpc: network.vpc,
      targets: [fargate.fargateService],
    });

    new cdk.CfnOutput(this, "FrontendURL", {
      value: alb.loadBalancer.loadBalancerDnsName,
    });
  }
}

import * as pulumi from "@pulumi/pulumi";
import * as aws from "@pulumi/aws";
import * as awsx from "@pulumi/awsx";

interface ECSComponentArgs {
  loadBalancer: awsx.lb.ApplicationLoadBalancer;
  image: awsx.ecr.Image;
}

export class ECSComponent extends pulumi.ComponentResource {
  constructor(
    name: string,
    args: ECSComponentArgs,
    opts?: pulumi.ResourceOptions
  ) {
    super("custom:resource:ECSComponent", name, {}, opts);

    const cluster = new aws.ecs.Cluster(
      `${name}-cluster`,
      {},
      { parent: this }
    );

    new awsx.ecs.FargateService(
      `${name}-service`,
      {
        cluster: cluster.arn,
        assignPublicIp: true,
        taskDefinitionArgs: {
          container: {
            name: "cya-ngin-app",
            image: args.image.imageUri,
            cpu: 128,
            memory: 512,
            essential: true,
            portMappings: [
              {
                containerPort: 80,
                targetGroup: args.loadBalancer.defaultTargetGroup,
              },
            ],
          },
        },
      },
      { parent: this }
    );

    this.registerOutputs();
  }
}

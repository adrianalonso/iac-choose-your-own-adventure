import * as cdk from "@aws-cdk/core";
import * as elbv2 from "@aws-cdk/aws-elasticloadbalancingv2";
import * as ec2 from "@aws-cdk/aws-ec2";
import * as ecs from "@aws-cdk/aws-ecs";

interface AlbProps {
  vpc: ec2.Vpc;
  targets: ecs.FargateService[];
}

export class AlbStack extends cdk.Construct {
  public readonly loadBalancer: elbv2.ApplicationLoadBalancer;
  public readonly lbSg: ec2.SecurityGroup;

  constructor(scope: cdk.Construct, id: string, props: AlbProps) {
    super(scope, id);

    this.lbSg = new ec2.SecurityGroup(this, "LoadBalancerSecurityGroup", {
      vpc: props.vpc,
      allowAllOutbound: true,
    });

    this.lbSg.addIngressRule(
      ec2.Peer.anyIpv4(),
      ec2.Port.tcp(80),
      "Allow HTTP inbound"
    );

    this.loadBalancer = new elbv2.ApplicationLoadBalancer(this, "LB", {
      vpc: props.vpc,
      internetFacing: true,
      securityGroup: this.lbSg,
      vpcSubnets: {
        subnets: props.vpc.selectSubnets({
          subnetType: ec2.SubnetType.PUBLIC,
          onePerAz: true,
        }).subnets,
      },
    });

    const listener = this.loadBalancer.addListener("Listener", {
      port: 80,
      open: true,
    });

    listener.addTargets("TargetGroup", {
      port: 80,
      targets: props.targets,
    });
  }
}

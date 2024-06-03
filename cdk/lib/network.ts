import * as cdk from "@aws-cdk/core";
import * as ec2 from "@aws-cdk/aws-ec2";

export class NetworkStack extends cdk.Construct {
  public readonly vpc: ec2.Vpc;

  constructor(scope: cdk.Construct, id: string) {
    super(scope, id);

    this.vpc = new ec2.Vpc(this, "MainVpc", {
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
  }
}

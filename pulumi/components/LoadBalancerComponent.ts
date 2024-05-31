import * as pulumi from "@pulumi/pulumi";
import * as awsx from "@pulumi/awsx";

export class LoadBalancerComponent extends pulumi.ComponentResource {
  public readonly loadBalancer: awsx.lb.ApplicationLoadBalancer;

  constructor(name: string, opts?: pulumi.ResourceOptions) {
    super("custom:resource:LoadBalancerComponent", name, {}, opts);

    this.loadBalancer = new awsx.lb.ApplicationLoadBalancer(
      `${name}-lb`,
      {},
      { parent: this }
    );

    this.registerOutputs({
      loadBalancer: this.loadBalancer,
    });
  }
}

import * as pulumi from "@pulumi/pulumi";
import {
  LoadBalancerComponent,
  ECRComponent,
  ECSComponent,
} from "./components";
import { applyTags } from "./utils";

const config = new pulumi.Config();
const projectName = pulumi.getProject();
const tags = config.requireObject<{ [key: string]: string }>("tags");

pulumi.runtime.registerStackTransformation(
  (args: pulumi.ResourceTransformationArgs) => applyTags(args, tags)
);

const loadBalancerComponent = new LoadBalancerComponent(projectName);
const ecrComponent = new ECRComponent(projectName);

new ECSComponent(projectName, {
  loadBalancer: loadBalancerComponent.loadBalancer,
  image: ecrComponent.image,
});

// Export the URL so we can easily access it.
export const frontendURL = pulumi.interpolate`http://${loadBalancerComponent.loadBalancer.loadBalancer.dnsName}`;

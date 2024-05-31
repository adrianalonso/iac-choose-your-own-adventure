import * as pulumi from "@pulumi/pulumi";
import * as awsx from "@pulumi/awsx";

export class ECRComponent extends pulumi.ComponentResource {
  public readonly image: awsx.ecr.Image;

  constructor(name: string, opts?: pulumi.ResourceOptions) {
    super("custom:resource:ECRComponent", name, {}, opts);

    const repo = new awsx.ecr.Repository(
      `${name}-repository`,
      {
        forceDelete: true,
      },
      { parent: this }
    );

    this.image = new awsx.ecr.Image(
      `${name}-app-image`,
      {
        repositoryUrl: repo.url,
        context: "./app",
        platform: "linux/amd64",
      },
      { parent: this }
    );

    this.registerOutputs({
      image: this.image,
    });
  }
}

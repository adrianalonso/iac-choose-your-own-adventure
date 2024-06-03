import * as cdk from "@aws-cdk/core";
import * as ecr from "@aws-cdk/aws-ecr";
import * as docker from "@aws-cdk/aws-ecr-assets";
import * as path from "path";

export class EcrStack extends cdk.Construct {
  public readonly repository: ecr.Repository;
  public readonly dockerImage: docker.DockerImageAsset;

  constructor(scope: cdk.Construct, id: string) {
    super(scope, id);

    this.repository = new ecr.Repository(this, "Repository", {
      repositoryName: "repo",
      removalPolicy: cdk.RemovalPolicy.DESTROY,
      imageScanOnPush: true,
    });

    this.dockerImage = new docker.DockerImageAsset(this, "MyDockerImage", {
      directory: path.join(__dirname, "../app"),
      platform: docker.Platform.LINUX_AMD64,
    });
  }
}

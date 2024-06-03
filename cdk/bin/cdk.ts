#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "@aws-cdk/core";
import { CYACdkStack } from "../lib/cdk-stack";
import { KeyValue } from "../lib/interfaces";

const app = new cdk.App();

const projectName = app.node.tryGetContext("projectName");
const tags: KeyValue = app.node.tryGetContext("tags");
const region = app.node.tryGetContext("region");

new CYACdkStack(app, "CdkStack", {
  projectName,
  env: {
    region,
  },
  tags,
});

cdk.Tags.of(app).add("Project", projectName);
if (tags) {
  for (const [key, value] of Object.entries(tags)) {
    cdk.Tags.of(app).add(key, value);
  }
}

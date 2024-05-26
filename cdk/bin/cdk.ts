#!/usr/bin/env node
import "source-map-support/register";
import * as cdk from "@aws-cdk/core";
import { MyCdkStack } from "../lib/cdk-stack";

const app = new cdk.App();
new MyCdkStack(app, "CdkStack", {
  env: {
    region: "us-west-2", // Reemplaza 'us-west-2' con la región que desees
  },
});

import * as cdk from "@aws-cdk/core";

export type KeyValue = { [key: string]: string };
export interface ProjectProps extends cdk.StackProps {
  projectName: string;
  tags?: KeyValue;
}

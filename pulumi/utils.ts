import * as pulumi from "@pulumi/pulumi";

export const applyTags = (
  args: pulumi.ResourceTransformationArgs,
  tags: { [key: string]: string }
) => {
  const props = args.props as any;
  if (props.tags === undefined) {
    props.tags = {};
  }

  props.tags = { ...props.tags, ...tags };

  return { props, opts: args.opts };
};

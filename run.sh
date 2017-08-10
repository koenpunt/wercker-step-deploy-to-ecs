#!/bin/bash

# Check if input file exists
if [ -f "$WERCKER_DEPLOY_TO_ECS_TEMPLATE_FILE" ]; then
  debug "Will use $WERCKER_DEPLOY_TO_ECS_TEMPLATE_FILE as JSON template for the AWS ECS task"
else
  debug ""
fi

# Task file
TASKFILE="$WERCKER_STEP_ROOT/task.json"

# Copy template file
ls -la "$WERCKER_STEP_ROOT"
cp "$WERCKER_DEPLOY_TO_ECS_TEMPLATE_FILE" "$TASKFILE.template"
ls -la "$WERCKER_STEP_ROOT"
if [ -f "$TASKFILE.template" ]; then
  debug "$TASKFILE.template was found"
else
  debug "$TASKFILE.template was not found"
  exit 1
fi

# Run templating system
# "$WERCKER_STEP_ROOT/run-template.sh"
"$WERCKER_STEP_ROOT/template.sh" "$TASKFILE.template" > "$TASKFILE"
ls -la "$WERCKER_STEP_ROOT"
if [ -f "$TASKFILE" ]; then
  debug "$TASKFILE was found"
else
  debug "$TASKFILE was not found"
  exit 1
fi
debug "Task template has been processed"

# Install JQ
apk update && apk add jq
debug "JQ has been installed"

# Configure AWS
aws configure set aws_access_key_id "$WERCKER_DEPLOY_TO_ECS_AWS_KEY"
aws configure set aws_secret_access_key "$WERCKER_DEPLOY_TO_ECS_AWS_SECRET"
aws configure set default.region "$WERCKER_DEPLOY_TO_ECS_AWS_REGION"
debug "AWS CLI has been configured"

# Register new task revision
debug "Going to register task $TASKFILE, which is based on template $WERCKER_DEPLOY_TO_ECS_TEMPLATE_FILE"
aws ecs register-task-definition --cli-input-json "file://$TASKFILE" || exit 1

if [ -z "${WERCKER_DEPLOY_TO_ECS_CLUSTER}" ] || [ -z "${WERCKER_DEPLOY_TO_ECS_SERVICE}" ] ; then
  debug "Skipping service deployment because 'cluster' or 'service' is not set."
else
  debug "Going to update service in cluster $WERCKER_DEPLOY_TO_ECS_CLUSTER"
  aws ecs update-service --cluster "$WERCKER_DEPLOY_TO_ECS_CLUSTER" --service "$WERCKER_DEPLOY_TO_ECS_SERVICE" --task-definition "$WERCKER_DEPLOY_TO_ECS_TASK" || exit 1
  debug "Updated service has been deployed"
fi

# Deregister old tasks (keep the 2 newest versions)
aws ecs list-task-definitions --family-prefix "$WERCKER_DEPLOY_TO_ECS_TASK" --status "ACTIVE" --sort ASC | jq  ".taskDefinitionArns[:-2]" | jq -r ".[]" | while read line; do aws ecs deregister-task-definition --task-definition "$line"; done
debug "Old tasks have been deregistered"

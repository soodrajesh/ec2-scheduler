import json
import boto3
import os

ec2 = boto3.client('ec2')

def lambda_handler(event, context):
    instance_id = os.getenv('INSTANCE_ID')
    action = event.get('action')
    
    if action == 'start':
        response = ec2.start_instances(InstanceIds=[instance_id])
        print(f"Starting instance: {instance_id}")
    elif action == 'stop':
        response = ec2.stop_instances(InstanceIds=[instance_id])
        print(f"Stopping instance: {instance_id}")
    else:
        print("Invalid action. Must be 'start' or 'stop'.")
    
    return {
        'statusCode': 200,
        'body': json.dumps(f"Action {action} executed for instance {instance_id}")
    }

import boto3
region = 'ap-southeast-2'

def lambda_handler(event, context):
	environment = event["environment"]
	print("stopping all instances in the %s environment" % (environment))
	ec2 = boto3.client('ec2', region_name=region)
	response = ec2.describe_instances(
		Filters=[
			{
				'Name': 'tag:Environment',
				'Values': [environment]
			}
		]
	)
	for reservation in response["Reservations"]:
		for instance in reservation["Instances"]:
			print("instance [%s] is in [%s] state" % (instance["InstanceId"], instance["State"]["Name"]))
			if instance["State"]["Name"] == "running":
				print("stopping instance [%s]" % (instance["InstanceId"]))
				ec2.stop_instances(InstanceIds=[instance["InstanceId"]])
				print("instance [%s] stopped" % (instance["InstanceId"]))
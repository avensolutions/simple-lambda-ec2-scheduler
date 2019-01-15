# Really Simple Terraform Script to Stop EC2 Instances Based upon Tags

Module is used to package and deploy a lamdba function and cloudwatch event used to stop a running EC2 instance at a specified time each day based upon a given value for an EC2 tag named Environment.  

> Requires input variables for *schedule_expression* and *environment* (data passed to the function on each invocation)



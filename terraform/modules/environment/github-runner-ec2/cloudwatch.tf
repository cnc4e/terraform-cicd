

# CloudWatchイベント - EC2の定時起動
resource "aws_cloudwatch_event_rule" "start_github_runner_rule" {
  count = var.cloudwatch_enable_schedule ? 1 : 0

  name                = "${var.pj}-Github-Runner-StartRule"
  description         = "Start ${var.pj} Github Runner"
  schedule_expression = var.cloudwatch_start_schedule
}

resource "aws_cloudwatch_event_target" "start_github_runner" {
  count = var.cloudwatch_enable_schedule ? 1 : 0

  target_id = "StartInstanceTarget"
  arn       = "arn:aws:ssm:ap-southeast-2:456247443832:automation-definition/AWS-StartEC2Instance"
  rule      = aws_cloudwatch_event_rule.start_github_runner_rule.0.name
  role_arn  = aws_iam_role.event_invoke_assume_role.0.arn

  input = <<DOC
{
  "InstanceId": ["${aws_instance.github_runner.id}"],
  "AutomationAssumeRole": ["${aws_iam_role.github_runner_ssm_automation.0.arn}"]
}
DOC
}

# CloudWatchイベント - EC2の定時停止
resource "aws_cloudwatch_event_rule" "stop_github_runner_rule" {
  count = var.cloudwatch_enable_schedule ? 1 : 0

  name                = "${var.pj}-Github-Runner-StopRule"
  description         = "Stop ${var.pj} Github Runner"
  schedule_expression = var.cloudwatch_stop_schedule
}

resource "aws_cloudwatch_event_target" "stop_github_runner" {
  count = var.cloudwatch_enable_schedule ? 1 : 0

  target_id = "StopInstanceTarget"
  arn       = "arn:aws:ssm:ap-southeast-2:456247443832:automation-definition/AWS-StopEC2Instance"
  rule      = aws_cloudwatch_event_rule.stop_github_runner_rule.0.name
  role_arn  = aws_iam_role.event_invoke_assume_role.0.arn

  input = <<DOC
{
  "InstanceId": ["${aws_instance.github_runner.id}"],
  "AutomationAssumeRole": ["${aws_iam_role.github_runner_ssm_automation.0.arn}"]
}
DOC
}
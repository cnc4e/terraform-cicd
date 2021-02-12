data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = "${var.pj}-GitHubRunnerRole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    {
      "Name" = "${var.pj}-GitHubRunnerRole"
    },
    var.tags
  )
}

data "aws_iam_policy" "systems_manager" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "systems_manager" {
  role       = aws_iam_role.role.name
  policy_arn = data.aws_iam_policy.systems_manager.arn
}

resource "aws_iam_instance_profile" "github_runner" {
  name = "${var.pj}-github-runner-instance-profile"
  role = aws_iam_role.role.name
}

# 自動スケジュール設定
# SSM Automation用のIAM Role
data "aws_iam_policy_document" "github_runner_ssm_automation_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_runner_ssm_automation" {
  count = var.cloudwatch_enable_schedule ? 1 : 0

  name               = "${var.pj}-Github-Runner-SSMautomation"
  assume_role_policy = data.aws_iam_policy_document.github_runner_ssm_automation_trust.json
}

# SSM Automation用のIAM RoleにPolicy付与
resource "aws_iam_role_policy_attachment" "ssm-automation-atach-policy" {
  count = var.cloudwatch_enable_schedule ? 1 : 0

  role       = aws_iam_role.github_runner_ssm_automation.0.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

# CloudWatchイベント用のIAM Role
data "aws_iam_policy_document" "runner_event_invoke_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "event_invoke_assume_role" {
  count = var.cloudwatch_enable_schedule ? 1 : 0

  name               = "${var.pj}-Github-Runner-CloudWatchEventRole"
  assume_role_policy = data.aws_iam_policy_document.runner_event_invoke_assume_role.json
}
resource "aws_codepipeline" "codepipeline_with_manual_approval" {
  name     = var.name
  role_arn = aws_iam_role.codepipeline_role.arn

  count = var.auto_approve_pre_production_and_production_deployments ? 0 : 1

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"

    encryption_key {
      id   = aws_kms_key.artifacts.arn
      type = "KMS"
    }
  }

  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "ThirdParty"
      provider         = "GitHub"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        OAuthToken           = data.aws_ssm_parameter.github_oauth_token.value
        Owner                = var.github_organisation_name
        Repo                 = var.github_repo_name
        Branch               = var.git_branch_name
        PollForSourceChanges = "true"
      }
    }
  }

  stage {
    name = "Test"

    action {
      name            = "Test"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.test.name
      }
    }
  }

  stage {
    name = "Development"

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.development.name
      }
    }
  }

  stage {
    name = "Pre_Production"

    action {
      name     = "Approve"
      owner    = "AWS"
      category = "Approval"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Deploy to ${aws_codebuild_project.pre-production.name}?"
      }
      run_order = 1
    }

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.pre-production.name
      }
    }
  }

  stage {
    name = "Production"

    action {
      name     = "Approve"
      owner    = "AWS"
      category = "Approval"
      provider = "Manual"
      version  = "1"

      configuration = {
        CustomData = "Deploy to ${aws_codebuild_project.production.name}?"
      }
      run_order = 1
    }

    action {
      name            = "Deploy"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["source_output"]
      version         = "1"

      configuration = {
        ProjectName = aws_codebuild_project.production.name
      }
    }
  }
}

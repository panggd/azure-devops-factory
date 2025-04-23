resource "azuredevops_project" "project" {
  for_each           = var.map_projects
  name               = each.key
  description        = "Project ${each.key}"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
}

resource "azuredevops_git_repository" "repo" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  project_id     = azuredevops_project.project[each.value.project_key].id
  name           = each.value.repo_name
  default_branch = "refs/heads/main"

  initialization {
    init_type = "Clean"
  }
}

resource "azuredevops_git_repository_branch" "repo_branch_dev" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  repository_id = azuredevops_git_repository.repo[each.key].id
  name          = "refs/heads/dev"
}

resource "azuredevops_git_repository_branch" "repo_branch_stg" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  repository_id = azuredevops_git_repository.repo[each.key].id
  name          = "refs/heads/stg"
}

# add min reviewers to remind ourselves of branch policies
resource "azuredevops_branch_policy_min_reviewers" "branch_policy_dev" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  project_id = azuredevops_project.project[each.value.project_key].id
  enabled    = true
  blocking   = true

  settings {
    reviewer_count               = 2     # At least one mandatory review
    submitter_can_vote           = false # Prevent self-approval
    last_pusher_cannot_approve   = true  # Enforce segregation of duties
    on_push_reset_approved_votes = true  # Reset approvals on new commits

    scope {
      repository_id  = azuredevops_git_repository.repo["${each.value.project_key}-${each.value.repo_name}"].id
      repository_ref = "refs/heads/dev"
      match_type     = "Exact"
    }
  }
}

resource "azuredevops_branch_policy_min_reviewers" "branch_policy_minreviewers" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  project_id = azuredevops_project.project[each.value.project_key].id
  enabled    = true
  blocking   = true

  settings {
    reviewer_count               = 2     # At least one mandatory review
    submitter_can_vote           = false # Prevent self-approval
    last_pusher_cannot_approve   = true  # Enforce segregation of duties
    on_push_reset_approved_votes = true  # Reset approvals on new commits

    scope {
      repository_id  = null
      repository_ref = "refs/heads/dev"
      match_type     = "Exact"
    }

    scope {
      repository_id  = null
      repository_ref = "refs/heads/stg"
      match_type     = "Exact"
    }

    scope {
      match_type = "DefaultBranch"
    }
  }
}

resource "azuredevops_branch_policy_work_item_linking" "branch_policy_workitem" {
  for_each = {
    for repo in var.map_repos :
    "${repo.project_key}-${repo.repo_name}" => repo
  }

  project_id = azuredevops_project.project[each.value.project_key].id

  enabled  = true
  blocking = true

  settings {

    scope {
      repository_id  = null
      repository_ref = "refs/heads/dev"
      match_type     = "Exact"
    }

    scope {
      repository_id  = null
      repository_ref = "refs/heads/stg"
      match_type     = "Exact"
    }

    scope {
      match_type = "DefaultBranch"
    }
  }
}

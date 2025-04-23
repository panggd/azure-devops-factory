variable "org_id" {
  type    = string
  default = null
}

variable "definition" {
  description = "A strict map of projects and their repositories"
  type = map( # Outer map for projects
    object({
      repos = map(object({
        appName  = string
        language = string
      }))
    })
  )
}

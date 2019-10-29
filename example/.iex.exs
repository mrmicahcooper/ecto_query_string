import Ecto.Query
import EctoQueryString
alias Example.Repo
alias Example.{User, Project, Task}

query = from(user in User)

querystring =
  "select=id,username,age,projects.description,tasks.name,tasks.id,tasks.project_id,projects.id,projects.user_id&limit=1"

ecto_query_string = EctoQueryString.query(query, querystring)

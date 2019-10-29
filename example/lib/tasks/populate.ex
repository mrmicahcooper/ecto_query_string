defmodule Mix.Tasks.Example.Populate do
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")

    user =
      %Example.User{email: "foo@example.com", username: "foobar", age: 99}
      |> Example.Repo.insert!()

    user2 =
      %Example.User{email: "bar@example.com", username: "barbaz", age: 45}
      |> Example.Repo.insert!()

    project =
      %Example.Project{name: "Work", description: "do work", user_id: user.id}
      |> Example.Repo.insert!()

    project2 =
      %Example.Project{name: "Work Harder", description: "do work harder", user_id: user2.id}
      |> Example.Repo.insert!()

    %Example.Task{name: "task1", description: "task one", project_id: project.id}
    |> Example.Repo.insert!()

    %Example.Task{name: "task2", description: "task one", project_id: project.id}
    |> Example.Repo.insert!()

    %Example.Task{name: "task3", description: "task one", project_id: project.id}
    |> Example.Repo.insert!()

    %Example.Task{name: "task4", description: "task one", project_id: project2.id}
    |> Example.Repo.insert!()
  end
end

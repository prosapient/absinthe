defmodule Absinthe.Phase.Schema.Validation.NamesMustBeValid do
  @moduledoc false

  use Absinthe.Phase
  alias Absinthe.Blueprint


  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &validate_names/1)
    {:ok, bp}
  end

  defp validate_names(%{name: nil} = entity) do
    entity
  end

  defp validate_names(%struct{name: name} = entity) do
    if valid_name?(name) do
      entity
    else
      kind = Absinthe.Blueprint.Schema.struct_to_kind(struct)
      detail = %{artifact: "#{kind} name", value: entity.name}
      entity |> put_error(error(entity, detail))
    end
  end

  defp validate_names(entity) do
    entity
  end

  defp valid_name?(name) do
    Regex.match?(valid_name_regex(), name)
  end

  defp error(object, data) do
    %Absinthe.Phase.Error{
      message: explanation(data),
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: data
    }
  end

  defp valid_name_regex(), do: ~r/^[_A-Za-z][_0-9A-Za-z]*$/

  def explanation(%{artifact: artifact, value: value}) do
    artifact_name = String.capitalize(artifact)

    """
    #{artifact_name} #{inspect(value)} has invalid characters.

    Name does not match possible #{inspect(valid_name_regex())} regex.

    > Names in GraphQL are limited to this ASCII subset of possible characters to
    > support interoperation with as many other systems as possible.

    Reference: https://graphql.github.io/graphql-spec/June2018/#sec-Names
    """
  end
end

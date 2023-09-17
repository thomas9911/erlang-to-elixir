defmodule ErlangToElixir do
  @moduledoc """
  Documentation for `ErlangToElixir`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> ErlangToElixir.hello()
      :world

  """
  def hello do
    :world
  end

  def do_it do
    string = "fun(A) -> io:format(\"blah~n\") end."
    # {:ok, tokens, _} = :erl_scan.string(string)
    # {:ok, [abs_form]} = :erl_parse.parse_exprs(tokens)

    # # IO.inspect(abs_form)

    # # Code.string_to_quoted!("fn a -> :io.format('blah~n') end") |> IO.inspect()
    # IO.inspect(string)
    # IO.inspect(walker_erlang(abs_form) |> Macro.to_string() |> Code.format_string!() |> :erlang.iolist_to_binary() )

    # :ok
    convert(string)
    |> elem(1)
    |> Macro.to_string()
    |> Code.format_string!()
    |> :erlang.iolist_to_binary()
  end

  def convert(erlang_str) do
    erlang_str
    |> :erlang.binary_to_list()
    |> :erl_scan.string()
    |> case do
      {:ok, tokens, _} -> :erl_parse.parse_exprs(tokens)
      err -> err
    end
    |> case do
      {:ok, [abs_form]} -> {:ok, walker_erlang(abs_form)}
      {:ok, abs_form} -> {:ok, walker_erlang(abs_form)}
      err -> err
    end
  end

  def walker_erlang([head | tail]) do
    [walker_erlang(head) | walker_erlang(tail)]
  end

  def walker_erlang([]) do
    []
  end

  def walker_erlang({:fun, line, {:clauses, clauses}}) do
    {:fn, [line: line], Enum.map(clauses, &walker_erlang/1)}
  end

  def walker_erlang({:clause, line, arguments, _, [function_clause]}) do
    {:->, [line: line],
     [
       erlang_arguments_to_elixir(arguments),
       walker_erlang(function_clause)
     ]}
  end

  def walker_erlang({:match, line, {:var, _, variable}, {_, _, item}}) do
    {:=, [line: line], [{erlang_variable_to_elixir(variable), [], Elixir}, item]}
  end

  def walker_erlang({:call, line, remote, args}) do
    {remote_call_to_elixir(remote), [line: line], clause_arguments_to_elixir(args)}
  end

  def erlang_arguments_to_elixir(arguments) do
    Enum.map(arguments, &erlang_argument_to_elixir/1)
  end

  def erlang_argument_to_elixir({:var, line, variable_name}) do
    {
      erlang_variable_to_elixir(variable_name),
      [line: line],
      nil
    }
  end

  # def erlang_function_clause_to_elixir([
  #       {:call, line, remote, args}
  #     ]) do
  #   {remote_call_to_elixir(remote), [line: line], clause_arguments_to_elixir(args)}
  # end

  def remote_call_to_elixir({:remote, line, {:atom, _, module}, {:atom, _, function}}) do
    {:., [line: line], [module, function]}
  end

  def clause_arguments_to_elixir(args) do
    Enum.map(args, &clause_argument_to_elixir/1)
  end

  def clause_argument_to_elixir({:string, _, arg}), do: arg

  def clause_argument_to_elixir({:bin, line, arg}),
    do: {:<<>>, [line: line], Enum.map(arg, &clause_argument_to_elixir/1)}

  def clause_argument_to_elixir({:bin_element, _, {:integer, _, number}, :default, :default}),
    do: number

  def erlang_variable_to_elixir(variable_name) do
    variable_name |> Atom.to_string() |> String.downcase() |> String.to_atom()
  end
end

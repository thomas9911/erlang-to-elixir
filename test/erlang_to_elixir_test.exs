defmodule ErlangToElixirTest do
  use ExUnit.Case
  doctest ErlangToElixir

  def ast_to_string(ast) do
    ast
    |> Macro.to_string()
    |> Code.format_string!()
    |> :erlang.iolist_to_binary()
  end

  test "anonymous functions" do
    assert {:ok, ast} = ErlangToElixir.convert("fun(A) -> io:format(\"blah~n\") end.")
    assert "fn a -> :io.format('blah~n') end" == ast_to_string(ast)
  end

  test "number assignment" do
    assert {:ok, ast} = ErlangToElixir.convert("A = 123.")
    assert "a = 123" == ast_to_string(ast)
  end

  test "term_to_binary" do
    assert {:ok, ast} = ErlangToElixir.convert("erlang:term_to_binary(<<91, 97, 17>>).")
    assert ":erlang.term_to_binary(<<91, 97, 17>>)" == ast_to_string(ast)
  end
end

defmodule InbentoTest do
  use ExUnit.Case
  doctest Inbento

  test "greets the world" do
    assert Inbento.hello() == :world
  end
end

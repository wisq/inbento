defmodule Inbento.Puzzle do
  defstruct(
    board: nil,
    goal: nil,
    pieces: %{}
  )

  alias __MODULE__
  alias Inbento.{Board, Piece}

  def read(file) do
    File.read!(file)
    |> String.split("\n\n")
    |> Enum.map(&get_section_name/1)
    |> build()
  end

  defp get_section_name(blob) do
    [name, rest] = String.split(blob, "\n", parts: 2)
    {name, rest}
  end

  defp build(sections) do
    sections
    |> Enum.reduce(%Puzzle{}, &apply_section/2)
  end

  defp apply_section({"BOARD", data}, puzzle) do
    %Puzzle{puzzle | board: Board.parse(data)}
  end

  defp apply_section({"GOAL", data}, puzzle) do
    %Puzzle{puzzle | goal: Board.parse(data)}
  end

  defp apply_section({"P" <> n, data}, puzzle) when n in ["1", "2", "3", "4", "5"] do
    n = String.to_integer(n)
    piece = Piece.parse(data)
    %Puzzle{puzzle | pieces: Map.put(puzzle.pieces, n, piece)}
  end

  def drop_piece(%Puzzle{} = puzzle, index) do
    %Puzzle{puzzle | pieces: Map.delete(puzzle.pieces, index)}
  end

  def solved?(%Puzzle{board: b, goal: b, pieces: pieces}), do: pieces == %{}
  def solved?(%Puzzle{}), do: false
end

defmodule Inbento.Piece do
  @enforce_keys [:width, :height, :rows]
  defstruct(
    width: nil,
    height: nil,
    rows: [],
    fixed: false,
    special: []
  )

  alias __MODULE__
  alias Inbento.Board

  def parse("[" <> rest) do
    [instruction, data] = String.split(rest, "]\n", parts: 2)

    parse(data)
    |> apply_instruction(instruction)
  end

  def parse(data) do
    data
    |> String.split("\n")
    |> Enum.reject(fn
      "" -> true
      _ -> false
    end)
    |> Enum.map(&parse_row/1)
    |> build()
  end

  defp parse_row(row) do
    row
    |> String.graphemes()
    |> Enum.map(&parse_cell/1)
  end

  defp parse_cell("-"), do: nil
  defp parse_cell(c), do: c

  defp apply_instruction(piece, "fixed"), do: %Piece{piece | fixed: true}

  defp apply_instruction(piece, <<"rotate ", from::binary-size(1), " to ", to::binary-size(1)>>) do
    special = {:copy, from, to}
    %Piece{piece | special: [special | piece.special]}
  end

  defp build(rows) do
    height = Enum.count(rows)
    [width] = rows |> Enum.map(&Enum.count/1) |> Enum.uniq()

    %Piece{width: width, height: height, rows: rows}
  end

  def rotations(%Piece{fixed: true} = piece), do: [piece]
  def rotations(%Piece{width: 1, height: 1} = piece), do: [piece]

  def rotations(%Piece{} = piece) do
    p1 = piece
    p2 = rotate(p1)
    p3 = rotate(p2)
    p4 = rotate(p3)

    [p1, p2, p3, p4]
  end

  defp rotate(piece) do
    %Piece{
      height: piece.width,
      width: piece.height,
      special: piece.special,
      rows:
        piece.rows
        |> Enum.zip()
        |> Enum.map(fn row ->
          Tuple.to_list(row)
          |> Enum.reverse()
        end)
    }
  end

  def to_string(%Piece{} = p) do
    p.rows
    |> Enum.map(&row_to_string/1)
    |> Enum.join("\n")
  end

  defp row_to_string(row) do
    row
    |> Enum.map(&cell_to_string/1)
    |> Enum.join("")
  end

  defp cell_to_string(nil), do: "-"
  defp cell_to_string(c), do: c

  def apply_specials(piece, board, position) do
    piece.special
    |> Enum.reduce(piece, &apply_special(&2, piece, board, &1, position))
  end

  defp apply_special(piece, orig_piece, board, {:copy, from, to}, {x_off, y_off}) do
    {fx, fy} = find_cell_position(orig_piece, from)
    {tx, ty} = find_cell_position(orig_piece, to)

    value = Board.get_cell(board, fx + x_off, fy + y_off)
    piece |> replace_cell(tx, ty, value)
  end

  defp replace_cell(piece, x, y, value) do
    rows =
      piece.rows
      |> List.update_at(y, fn row ->
        row |> List.replace_at(x, value)
      end)

    %Piece{piece | rows: rows}
  end

  defp find_cell_position(piece, cell) do
    piece.rows
    |> Enum.with_index()
    |> Enum.find_value(fn {row, y_index} ->
      case row |> Enum.find_index(&(&1 == cell)) do
        nil -> nil
        x_index -> {x_index, y_index}
      end
    end)
    |> then(fn
      {_, _} = pos -> pos
      nil -> raise "Cannot find #{inspect(cell)} in #{inspect(piece)}"
    end)
  end
end

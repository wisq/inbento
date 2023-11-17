defmodule Inbento.Board do
  @enforce_keys [:width, :height, :rows]
  defstruct(
    width: nil,
    height: nil,
    rows: []
  )

  alias __MODULE__
  alias Inbento.Piece

  def parse(data) do
    data
    |> Piece.parse()
    |> build()
  end

  defp build(%Piece{height: h, width: w, rows: r}) do
    %Board{
      height: h,
      width: w,
      rows: r
    }
  end

  def possible_placements(%Board{} = board, %Piece{} = piece) do
    x_offsets = 0..(board.width - piece.width)
    y_offsets = 0..(board.height - piece.height)

    x_offsets
    |> Enum.flat_map(fn x_offset ->
      y_offsets
      |> Enum.map(fn y_offset ->
        {x_offset, y_offset}
      end)
    end)
  end

  def apply_piece(%Board{} = board, %Piece{} = piece, {x_offset, y_offset} = position) do
    piece = Piece.apply_specials(piece, board, position)

    board.rows
    |> Enum.slice(y_offset, piece.height)
    |> Enum.zip_with(piece.rows, fn board_row, piece_row ->
      board_row
      |> Enum.slice(x_offset, piece.width)
      |> Enum.zip_with(piece_row, &apply_cell/2)
      |> list_replace(board_row, x_offset, piece.width)
    end)
    |> list_replace(board.rows, y_offset, piece.height)
    |> then(fn rows ->
      %Board{board | rows: rows}
    end)
  end

  defp apply_cell(a, nil), do: a
  defp apply_cell(_, b), do: b

  defp list_replace(new, old, 0, count), do: new ++ Enum.drop(old, count)

  defp list_replace(new, old, index, count) do
    {pre, rest} = old |> Enum.split(index)
    {_, post} = rest |> Enum.split(count)
    pre ++ new ++ post
  end

  def get_cell(board, x, y) do
    board.rows
    |> Enum.at(y)
    |> Enum.at(x)
  end
end

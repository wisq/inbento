defmodule Inbento.Solver do
  defmodule State do
    @enforce_keys [:puzzle, :steps]
    defstruct(
      steps: [],
      puzzle: nil
    )
  end

  alias Inbento.{Puzzle, Board, Piece}

  def solve(%Puzzle{} = puzzle) do
    %State{puzzle: puzzle, steps: []}
    |> puzzle_solutions()
  end

  defp puzzle_solutions(state) do
    if Puzzle.solved?(state.puzzle) do
      [state]
    else
      state.puzzle.pieces
      |> Enum.flat_map(fn {index, piece} ->
        state = %State{state | puzzle: Puzzle.drop_piece(state.puzzle, index)}
        piece_solutions(state, index, piece)
      end)
    end
  end

  defp piece_solutions(state, index, piece) do
    piece
    |> Piece.rotations()
    |> Enum.with_index()
    |> Enum.flat_map(fn {rotated, n_times} ->
      state
      |> add_rotate_step(index, n_times)
      |> rotated_piece_solutions(index, rotated)
    end)
  end

  defp add_rotate_step(state, _, 0), do: state

  defp add_rotate_step(state, index, n_times) do
    %State{state | steps: [{:rotate, index, n_times} | state.steps]}
  end

  defp rotated_piece_solutions(state, index, piece) do
    Board.possible_placements(state.puzzle.board, piece)
    |> Enum.flat_map(fn position ->
      board = state.puzzle.board |> Board.apply_piece(piece, position)
      puzzle = %Puzzle{state.puzzle | board: board}

      %State{
        steps: [{:apply, index, position} | state.steps],
        puzzle: puzzle
      }
      |> puzzle_solutions()
    end)
  end
end

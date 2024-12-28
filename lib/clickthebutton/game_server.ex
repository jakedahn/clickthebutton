defmodule Clickthebutton.GameServer do
  use GenServer
  require Logger

  @table_name :ctb_game_state
  # Save every 1 minute
  @save_interval :timer.minutes(1)
  @topic "game:scores"

  # Client API
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def increment_score(user_id) do
    GenServer.call(__MODULE__, {:increment, user_id})
  end

  def get_score(user_id) do
    GenServer.call(__MODULE__, {:get_score, user_id})
  end

  def get_leaderboard do
    GenServer.call(__MODULE__, :get_leaderboard)
  end

  # Server Callbacks
  @impl true
  def init(_opts) do
    table = :ets.new(@table_name, [:set, :named_table, :public])
    schedule_save()
    {:ok, %{table: table, last_save: DateTime.utc_now(), dirty: false}}
  end

  @impl true
  def handle_call({:increment, user_id}, _from, state) do
    new_score =
      @table_name
      |> :ets.lookup(user_id)
      |> case do
        [{^user_id, score}] -> score + 1
        [] -> 1
      end
      |> tap(fn score -> :ets.insert(@table_name, {user_id, score}) end)

    # Broadcast the update to all subscribers
    Phoenix.PubSub.broadcast(Clickthebutton.PubSub, @topic, {:score_updated, user_id, new_score})

    {:reply, new_score, %{state | dirty: true}}
  end

  @impl true
  def handle_call({:get_score, user_id}, _from, state) do
    score =
      @table_name
      |> :ets.lookup(user_id)
      |> case do
        [{^user_id, score}] -> score
        [] -> 0
      end

    {:reply, score, state}
  end

  @impl true
  def handle_call(:get_leaderboard, _from, state) do
    leaderboard =
      @table_name
      |> :ets.tab2list()
      |> Enum.sort_by(fn {_user, score} -> score end, :desc)
      |> Enum.take(100)

    {:reply, leaderboard, state}
  end

  @impl true
  def handle_info(:save_to_disk, %{dirty: false} = state) do
    schedule_save()
    {:noreply, state}
  end

  @impl true
  def handle_info(:save_to_disk, state) do
    # Save ETS table to disk
    save_path = "priv/game_state.dat"
    :ets.tab2file(@table_name, String.to_charlist(save_path))
    Logger.info("Game state saved to disk")

    schedule_save()
    {:noreply, %{state | last_save: DateTime.utc_now(), dirty: false}}
  end

  defp schedule_save do
    Process.send_after(self(), :save_to_disk, @save_interval)
  end
end

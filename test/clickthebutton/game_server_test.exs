defmodule Clickthebutton.GameServerTest do
  use ExUnit.Case, async: false
  require Logger

  alias Clickthebutton.GameServer

  @save_path "priv/game_state_test.dat"

  setup do
    # Clean up any existing test file
    cleanup_test_file()

    # Reset the ETS table instead of restarting the GenServer
    :ets.delete_all_objects(:ctb_game_state)

    :ok
  end

  describe "score management" do
    test "increments score for new user" do
      assert GameServer.get_score("user1") == 0
      assert GameServer.increment_score("user1") == 1
      assert GameServer.get_score("user1") == 1
    end

    test "increments existing score" do
      GameServer.increment_score("user2")
      GameServer.increment_score("user2")
      assert GameServer.get_score("user2") == 2
    end

    test "handles multiple users" do
      GameServer.increment_score("user3")
      GameServer.increment_score("user4")
      GameServer.increment_score("user3")

      assert GameServer.get_score("user3") == 2
      assert GameServer.get_score("user4") == 1
    end
  end

  describe "leaderboard" do
    test "returns sorted leaderboard" do
      # Create some scores
      GameServer.increment_score("user5")
      GameServer.increment_score("user5")
      GameServer.increment_score("user6")
      GameServer.increment_score("user7")
      GameServer.increment_score("user7")
      GameServer.increment_score("user7")

      leaderboard = GameServer.get_leaderboard()
      assert length(leaderboard) > 0

      # Check sorting
      [{top_user, top_score} | _rest] = leaderboard
      assert top_user == "user7"
      assert top_score == 3
    end

    test "limits leaderboard to top 100" do
      # Create more than 100 users
      for i <- 1..110 do
        user_id = "user#{i}"
        GameServer.increment_score(user_id)
      end

      leaderboard = GameServer.get_leaderboard()
      assert length(leaderboard) == 100
    end
  end

  describe "persistence" do
    test "saves and loads state" do
      # Create some initial state
      GameServer.increment_score("persist_user1")
      GameServer.increment_score("persist_user1")
      GameServer.increment_score("persist_user2")

      # Force a save
      send(GameServer, :save_to_disk)
      # Give it time to save
      Process.sleep(500)

      # Simulate restart by sending init message
      send(GameServer, :reinit_for_test)
      # Give it time to load
      Process.sleep(500)

      # Verify state was restored
      assert GameServer.get_score("persist_user1") == 2
      assert GameServer.get_score("persist_user2") == 1
    end
  end

  # Helper functions
  defp cleanup_test_file do
    File.rm(@save_path)
  end
end

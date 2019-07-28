defmodule ELM.TestPlanFactory do
  def pool(user_type) when is_bitstring(user_type) do
    %{
      type: user_type,
      time_offset: 0,
      user_count: 0,
      actions: []
    }
  end

  def produce(pool, number, period) when number > 0 and period > 0 do
    actions = make_test_actions(:start_user, pool[:type], pool[:time_offset], number, period)

    pool
    |> Map.update!(:actions, &(&1 ++ actions))
    |> Map.update!(:time_offset, &(&1 + period))
    |> Map.update!(:user_count, &(&1 + number))
  end

  def hold_on(pool, period) when period > 0 do
    %{pool | time_offset: pool[:time_offset] + period}
  end

  defp make_test_actions(action_type, user_type, time_offset, number, period)
       when number > 0 and period > 0 do
    count = min(number, period)

    nstep = floor(number / count)
    pstep = floor(period / count)

    nrem = number - nstep * count
    prem = period - pstep * count

    1..count
    |> Enum.map(fn i ->
      nerr = if i <= nrem, do: 1, else: 0
      perr = if i <= prem, do: 1, else: 0

      %{
        action: action_type,
        type: user_type,
        number: nstep + nerr,
        time: time_offset + i * pstep + perr
      }
    end)
  end
end

defmodule ELM.Load.Report.TranTimesPercentilesTest do
  alias ELM.Load.Report.TranTimesPercentiles, as: Report
  use ExUnit.Case, async: true
  doctest Report

  test "Transaction times percentiles test" do
    assert Report.get_report_timeline() == []

    rs1 = 1..100 |> Enum.map(fn _ -> :rand.uniform(1000) end)
    srs1 = rs1 |> Enum.sort()
    tran1 = rs1 |> Enum.map(fn rs -> {0, "UserA", "action", :tran_completed, rs} end)

    Report.update_report(tran1)
    Report.update_report([])

    timeline1 = Report.get_report_timeline()

    assert length(timeline1) == 101
    assert hd(timeline1)[:y] == hd(srs1)
    assert Enum.at(timeline1, 30)[:y] == Enum.at(srs1, 30)
    assert Enum.at(timeline1, 50)[:y] == Enum.at(srs1, 50)
    assert Enum.at(timeline1, 90)[:y] == Enum.at(srs1, 90)
    assert Enum.at(timeline1, 95)[:y] == Enum.at(srs1, 95)
    assert Enum.at(timeline1, 97)[:y] == Enum.at(srs1, 97)
    assert Enum.at(timeline1, 99)[:y] == Enum.at(srs1, 99)
    assert List.last(timeline1)[:y] == List.last(srs1)

    Report.clear_report()

    assert Report.get_report_timeline() == []
  end
end

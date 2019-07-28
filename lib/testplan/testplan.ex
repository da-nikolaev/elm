defmodule TestPlan do
  import ELM.TestPlanFactory

  def test_postcard do
    user =
      pool("Postcard")
      |> produce(500, 60)
      |> hold_on(90)

    [user]
  end
end

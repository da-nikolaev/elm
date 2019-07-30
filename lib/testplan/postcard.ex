defmodule Postcard do
  require Logger
  import ELM.User
  @behaviour ELM.User

  def init(_) do
    conn = connect("192.168.1.175", 5000)

    {conn, :home}
  end

  def dispose(conn) do
    close(conn)
  end

  def home(conn, _) do
    _ = get(conn, "/")

    {conn,
     {:pacing, 1000,
      {:open_country,
       Enum.random([
         "Австралия",
         "Австрия",
         "Армения",
         "Бельгия",
         "Болгария",
         "Босния и Герцеговина",
         "Венгрия",
         "Германия",
         "Германия - ГДР",
         "Греция",
         "Грузия",
         "Египет",
         "Израиль",
         "Ирландия",
         "Испания",
         "Италия",
         "Казахстан",
         "Кипр",
         "Киргизия",
         "Китай",
         "Куба",
         "Мальта",
         "Монголия",
         "Нидерланды",
         "Парагвай",
         "Польша",
         "Португалия",
         "Россия",
         "Румыния",
         "Сербия",
         "Словакия",
         "СССР",
         "США",
         "Таджикистан",
         "Таиланд",
         "Танзания",
         "Турция",
         "Уганда",
         "Украина",
         "Франция",
         "Чехия",
         "Чехословакия",
         "Швейцария"
       ])}}}
  end

  def open_country(conn, name) do
    _ = get(conn, "/country/" <> URI.encode(name))

    {conn, {:pacing, 1000, {:open_coin, 2}}}
  end

  def open_coin(conn, id) do
    _ = get(conn, "/coins/" <> Integer.to_string(id))

    {conn, {:pacing, 1000, {:open_postcards, []}}}
  end

  def open_postcards(conn, _) do
    _ = get(conn, "/postcards")

    {conn,
     {:pacing, 1000,
      {:open_postcards_by_code,
       Enum.random([
         "AU",
         "AT",
         "BY",
         "BE",
         "GB"
       ])}}}
  end

  def open_postcards_by_code(conn, code) do
    _ = get(conn, "/country_postcards/" <> URI.encode(code))

    {conn, {:pacing, 1000, {:open_postcard_by_id, "BE-638555"}}}
  end

  def open_postcard_by_id(conn, id) do
    _ = get(conn, "/postcard/" <> id)

    {conn, {:pacing, {1000, 500}, {:open_stamps, []}}}
  end

  def open_stamps(conn, _) do
    _ = get(conn, "/stamps")

    {conn,
     {:pacing, 1000,
      {:open_stamps_by_country,
       Enum.random([
         "Австралия",
         "Австрия",
         "Беларусь",
         "Бельгия",
         "Великобритания",
         "Вьетнам",
         "Германия",
         "Гонконг",
         "Индия",
         "Индонезия",
         "Италия",
         "Казахстан",
         "Китай",
         "Корея Южная",
         "Латвия",
         "Литва",
         "Нидерланды",
         "Польша",
         "Россия",
         "США",
         "Тайвань",
         "Турция",
         "Финляндия",
         "Франция",
         "Хорватия",
         "Черногория",
         "Чехия",
         "Швейцария",
         "Эстония",
         "Япония"
       ])}}}
  end

  def open_stamps_by_country(conn, country) do
    _ = get(conn, "/country_stamps/" <> URI.encode(country))

    {conn, {:pacing, 1000, {:open_stamp_by_id, 6}}}
  end

  def open_stamp_by_id(conn, id) do
    _ = get(conn, "/stamp/" <> Integer.to_string(id))

    {conn, :stop}
  end
end

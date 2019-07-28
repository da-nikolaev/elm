defmodule Postcard do
  require Logger
  use ELM.User

  main(:home)

  defp get!(url) do
    # Process.sleep(:rand.uniform(100))
    _ = :httpc.request(:get, {String.to_charlist(url), []}, [], [])
  end

  def home(_opts) do
    _ = get!("http://192.168.1.175:5000")

    {:pacing, 1000, :open_country,
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
     ])}
  end

  def open_country(name) do
    _ = get!("http://192.168.1.175:5000/country/" <> URI.encode(name))

    {:pacing, 1000, :open_coin, 2}
  end

  def open_coin(id) do
    _ = get!("http://192.168.1.175:5000/coins/" <> Integer.to_string(id))

    {:pacing, 1000, :open_postcards, []}
  end

  def open_postcards(_opts) do
    _ = get!("http://192.168.1.175:5000/postcards")

    {:pacing, 1000, :open_postcards_by_code,
     Enum.random([
       "AU",
       "AT",
       "BY",
       "BE",
       "GB"
     ])}
  end

  def open_postcards_by_code(code) do
    _ = get!("http://192.168.1.175:5000/country_postcards/" <> URI.encode(code))

    {:pacing, 1000, :open_postcard_by_id, "BE-638555"}
  end

  def open_postcard_by_id(id) do
    _ = get!("http://192.168.1.175:5000/postcard/" <> id)

    {:pacing, 1000, :open_stamps, []}
  end

  def open_stamps(_opts) do
    _ = get!("http://192.168.1.175:5000/stamps")

    {:pacing, {1000, 500}, :open_stamps_by_country,
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
     ])}
  end

  def open_stamps_by_country(country) do
    _ = get!("http://192.168.1.175:5000/country_stamps/" <> URI.encode(country))

    {:pacing, 1000, :open_stamp_by_id, 6}
  end

  def open_stamp_by_id(id) do
    _ = get!("http://192.168.1.175:5000/stamp/" <> Integer.to_string(id))

    :stop
  end
end

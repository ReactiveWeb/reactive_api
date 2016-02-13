defmodule Reactive.Json do
  require Logger

  def encode(term) do
    :jsx.encode(term2js(term))
  end

  def decode(json) do
    js2term(:jsx.decode(json,[labels: :attempt_atom]))
  end

  def term2js(:true) do
    :true
  end
  def term2js(:false) do
    :false
  end
  def term2js(:null) do
    :null
  end
  def term2js(:undefined) do
    :undefined
  end
  def term2js(tv) when is_atom(tv) do
    %{ "@a" => :erlang.atom_to_binary(tv,:utf8) }
  end
  def term2js(tv) when is_tuple(tv) do
    %{ "@t" => Enum.map(:erlang.tuple_to_list(tv) , &term2js/1 ) }
  end
  def term2js(tv) when is_list(tv) do
    Enum.map(tv , &term2js/1 )
  end
  def term2js(tv) when is_map(tv) do
    for {key, val} <- tv, into: %{}, do: {key, term2js(val) }
  end
  def term2js(tv) do
    tv
  end

  def js2term(%{ "@a" => atom }) do
    :erlang.binary_to_existing_atom(atom,:utf8)
  end
  def js2term(%{ "@t" => tuple }) do
    :erlang.list_to_tuple(Enum.map(tuple , &js2term/1 ))
  end
  def js2term(jsv) when is_list(jsv) do
    Enum.map(jsv , &js2term/1 )
  end
  def js2term(jsv) when is_map(jsv) do
    for {key, val} <- jsv, into: %{}, do: {key, js2term(val) }
  end
  def js2term(jsv) do
    jsv
  end
end
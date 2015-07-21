#!/usr/bin/env elixir



[fileName,outFileName]=System.argv()

code=File.read!(fileName)
file_ast=Code.string_to_quoted!(code)

{:defmodule, _,
  [{:__aliases__, _, api_name}, [do: {:__block__,[], [{:use,_,[{:__aliases__, _, [:Reactive, :Api]}]} | block_ast]  }]]}=file_ast

IO.inspect block_ast

api_defs = List.foldl(block_ast,%{},fn
  ({:allow,_,[{:__aliases__, _, module_name},params]},acc) ->
    Map.put(acc,Enum.join(module_name,"."),params)
  (_,acc) -> acc
end)

IO.inspect api_defs

File.write(outFileName,:jsx.encode(api_defs))

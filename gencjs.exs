#!/usr/bin/env elixir



[fileName,outFileName]=System.argv()

code=File.read!(fileName)
file_ast=Code.string_to_quoted!(code)

{:defmodule, _,
  [{:__aliases__, _, api_name}, [do: {:__block__,[], [{:use,_,[{:__aliases__, _, [:Reactive, :Api]}]} | block_ast]  }]]}=file_ast

IO.inspect block_ast

clean_name=fn
  ({v,_p}) -> v
  v -> v
end

api_defs = List.foldl(block_ast,%{},fn
  ({:allow,_,[{:__aliases__, _, module_name},params]},acc) ->
    Map.put(acc,Enum.join(module_name,"."),Enum.map(params,fn
        ({k,v}) when is_list(v) -> {k,Enum.map(v,clean_name)}
        ({k,v}) -> {k,[clean_name.(v)]}
      end ))
  (_,acc) -> acc
end)

IO.inspect api_defs

File.write(outFileName,"rapi=require('./reactive-api.js')\nmodule.exports=rapi(" <> :jsx.encode(api_defs) <> ")")

defmodule State do
  defstruct limit: 0, sup: nil, refs: nil, queue: :queue:new()
end

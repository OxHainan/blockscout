defmodule BlockScoutWeb.Tokens.Instance.MetadataController do
  use BlockScoutWeb, :controller

  alias BlockScoutWeb.Controller
  alias Explorer.Chain

  def index(conn, %{"token_id" => token_address_hash, "instance_id" => token_id}) do
    options = [necessity_by_association: %{[contract_address: :smart_contract] => :optional}]

    with {:ok, hash} <- Chain.string_to_address_hash(token_address_hash),
         {:ok, token} <- Chain.token_from_address_hash(hash, options),
         {:ok, token_instance} <-
           Chain.erc721_or_erc1155_token_instance_from_token_id_and_token_address(token_id, hash) do
      if token_instance.metadata do
        render(
          conn,
          "index.html",
          token_instance: %{instance: token_instance, token_id: Decimal.new(token_id)},
          current_path: Controller.current_full_path(conn),
          token: token,
          total_token_transfers: Chain.count_token_transfers_from_token_hash_and_token_id(hash, token_id)
        )
      else
        not_found(conn)
      end
    else
      _ ->
        not_found(conn)
    end
  end

  def index(conn, _) do
    not_found(conn)
  end
end

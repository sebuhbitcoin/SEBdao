// SPDX-FileCopyrightText: 2021 TQ Tezos
// SPDX-License-Identifier: LicenseRef-MIT-TQ

#include "common/types.mligo"
#include "defaults.mligo"
#include "types.mligo"
#include "proposal.mligo"
#include "helper/unpack.mligo"
#include "base_DAO.mligo"

#include "treasuryDAO/types.mligo"

// -------------------------------------
// Configuration Lambdas
// -------------------------------------

let treasury_DAO_proposal_check (params, extras : propose_params * contract_extra) : bool =
  let proposal_size = Bytes.size(params.proposal_metadata) in
  let frozen_scale_value = unpack_nat(find_big_map("frozen_scale_value", extras)) in
  let frozen_extra_value = unpack_nat(find_big_map("frozen_extra_value", extras)) in
  let max_proposal_size = unpack_nat(find_big_map("max_proposal_size", extras)) in
  let min_xtz_amount = unpack_tez(find_big_map("min_xtz_amount", extras)) in
  let max_xtz_amount = unpack_tez(find_big_map("max_xtz_amount", extras)) in

  let required_token_lock = frozen_scale_value * proposal_size + frozen_extra_value in
  let has_correct_token_lock =
    (params.frozen_token = required_token_lock) && (proposal_size < max_proposal_size) in

  if has_correct_token_lock then
    let pm = unpack_proposal_metadata(params.proposal_metadata) in

    let is_all_transfers_valid (is_valid, transfer_type: bool * transfer_type) =
      match transfer_type with
      | Token_transfer_type tt -> is_valid
      | Xtz_transfer_type xt -> is_valid && min_xtz_amount <= xt.amount && xt.amount <= max_xtz_amount
    in
      List.fold is_all_transfers_valid pm.transfers true
  else
    false

let treasury_DAO_rejected_proposal_return_value (params, extras : proposal * contract_extra) : nat =
  let slash_scale_value = unpack_nat(find_big_map("slash_scale_value", extras)) in
  let slash_division_value =  unpack_nat(find_big_map("slash_division_value", extras))
  in (slash_scale_value * params.proposer_frozen_token) / slash_division_value

let treasury_DAO_decision_lambda (proposal, extras : proposal * contract_extra)
    : operation list * contract_extra =
  let propose_param : propose_params = {
    frozen_token = proposal.proposer_frozen_token;
    proposal_metadata = proposal.metadata
    } in
  let pm = unpack_proposal_metadata(proposal.metadata) in
  let handle_transfer (acc, transfer_type : (bool * contract_extra * operation list) * transfer_type) =
      let (is_valid, extras, ops) = acc in
      if is_valid then
        match transfer_type with
          Token_transfer_type tt ->
            let result = match (Tezos.get_entrypoint_opt "%transfer" tt.contract_address
                : transfer_params contract option) with
              Some contract ->
                let token_transfer_operation = Tezos.transaction tt.transfer_list 0mutez contract
                in (is_valid, extras, token_transfer_operation :: ops)
            | None ->
                (false, extras, ops)
            in result
        | Xtz_transfer_type xt ->
            let result = match (Tezos.get_contract_opt xt.recipient
                : unit contract option) with
              Some contract ->
                let xtz_transfer_operation = Tezos.transaction unit xt.amount contract
                in (is_valid, extras, xtz_transfer_operation :: ops)
            | None ->
                (false, extras, ops)
            in result
      else
        (false, extras, ops)
  in
  let (is_valid, extras, ops) = List.fold handle_transfer pm.transfers (true, extras, ([] : operation list)) in
  if is_valid then
    (ops, extras)
  else
    // TODO: [#87] Improve handling of failed proposals
    (failwith("FAIL_DECISION_LAMBDA") : operation list * contract_extra)

// A custom entrypoint needed to receive xtz, since most `basedao` entrypoints
// prohibit non-zero xtz transfer.
let receive_xtz_entrypoint (params, full_store : bytes * full_storage) : return =
  (([]: operation list), full_store.0)

// -------------------------------------
// Storage Generator
// -------------------------------------

let default_treasury_DAO_full_storage (data : initial_treasuryDAO_storage) : full_storage =
  let (store, config) = default_full_storage (data.base_data) in
  let new_storage = { store with
    extra = Big_map.literal [
          ("frozen_scale_value" , Bytes.pack data.frozen_scale_value);
          ("frozen_extra_value" , Bytes.pack data.frozen_extra_value);
          ("max_proposal_size" , Bytes.pack data.max_proposal_size);
          ("slash_scale_value" , Bytes.pack data.slash_scale_value);
          ("slash_division_value" , Bytes.pack data.slash_division_value);
          ("min_xtz_amount" , Bytes.pack data.min_xtz_amount);
          ("max_xtz_amount" , Bytes.pack data.max_xtz_amount);
          ];
  } in
  let new_config = { config with
    proposal_check = treasury_DAO_proposal_check;
    rejected_proposal_return_value = treasury_DAO_rejected_proposal_return_value;
    decision_lambda = treasury_DAO_decision_lambda;
    custom_entrypoints = Big_map.literal [("receive_xtz", Bytes.pack (receive_xtz_entrypoint))];
    }
  in (new_storage, new_config)

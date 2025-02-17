-- SPDX-FileCopyrightText: 2021 TQ Tezos
-- SPDX-License-Identifier: LicenseRef-MIT-TQ

-- | A Treasury DAO can be used to store key value pair @(k, v)@
module Lorentz.Contracts.TreasuryDAO
  ( treasuryDaoContract
  , config
  )
  where

import Lorentz
import qualified Lorentz.Contracts.Spec.FA2Interface as FA2
import Universum ((*))

import qualified Lorentz.Contracts.BaseDAO as DAO
import qualified Lorentz.Contracts.BaseDAO.Common.Types as DAO
import qualified Lorentz.Contracts.BaseDAO.Types as DAO
import Lorentz.Contracts.BaseDAO.Management (ensureNotMigrated)
import Lorentz.Contracts.TreasuryDAO.Doc
import Lorentz.Contracts.TreasuryDAO.Types

{-# ANN module ("HLint: ignore Reduce duplication" :: Text) #-}

treasuryDaoProposalCheck
  :: forall s store.
     ( DAO.StorageC store TreasuryDaoContractExtra TreasuryDaoProposalMetadata
     )
  => DAO.ProposeParams TreasuryDaoProposalMetadata : store : s
  :-> Bool : s
treasuryDaoProposalCheck = do
  getField #ppProposalMetadata
  packRaw;
  size; toNamed #proposalSize

  duupX @3
  stToField #sExtra; toFieldNamed #ceMaxProposalSize; dip dup
  if #ceMaxProposalSize >. #proposalSize then do
    fromNamed #proposalSize
    duupX @3;
    stackType @(store : Natural : DAO.ProposeParams TreasuryDaoProposalMetadata : store : s)
    stToField #sExtra

    getField #ceFrozenScaleValue; dip swap; mul
    swap; toField #ceFrozenExtraValue; add

    toNamed #requireValue; duupX @2
    toFieldNamed #ppFrozenToken; swap

    if #requireValue ==. #ppFrozenToken then do
      -- Check if the proposal is xtz or not
      toField #ppProposalMetadata
      toField #npTransfers
      push True; swap -- track whether or not it contains proper xtz amount
      iter $ do
        caseT
          ( #cXtz_transfer_type /-> do
              toFieldNamed #xtAmount;
              duupX @3; stToField #sExtra
              dupTop2;
              toFieldNamed #ceMaxXtzAmount
              if #ceMaxXtzAmount >=. #xtAmount then do
                toFieldNamed #ceMinXtzAmount
                if #ceMinXtzAmount <=. #xtAmount then do
                  nop
                else do
                  drop; push False
              else do
                dropN @3
                push False

          , #cToken_transfer_type /-> do
              drop;
          )
      dip drop
    else do
      dropN @2
      push False
  else do
    -- submitted proposal size is bigger than max proposal size
    dropN @3
    push False

treasuryDaoRejectedProposalReturnValue
  :: forall s store.
      ( DAO.StorageC store TreasuryDaoContractExtra TreasuryDaoProposalMetadata
      )
  =>  DAO.Proposal TreasuryDaoProposalMetadata : store : s
  :-> ("slash_amount" :! Natural) : s
treasuryDaoRejectedProposalReturnValue = do
  toField #pProposerFrozenToken
  swap;
  stToField #sExtra

  getField #ceSlashScaleValue; dip swap; mul
  swap; toField #ceSlashDivisionValue; swap; ediv
  ifSome car $
    push (0 :: Natural)
  toNamed #slash_amount

-- | Update the propose changes
decisionLambda
  :: forall s store.
  ( DAO.StorageC store TreasuryDaoContractExtra TreasuryDaoProposalMetadata
  )
  =>  DAO.Proposal TreasuryDaoProposalMetadata : store : s
  :-> List Operation : store : s
decisionLambda = do
  toField #pMetadata

  toField #npTransfers
  nil
  push False -- track wherher or not there is a fail operation
  dig @2
  iter $ do
    caseT
      ( #cXtz_transfer_type /-> do
          stackType @(DAO.XtzTransfer : Bool : [Operation] : store : s)
          getField #xtRecipient;
          contractCallingUnsafe @() DefEpName
          ifSome ( do
              swap
              toField #xtAmount;
              push ();
              transferTokens
              dip swap; cons; swap
            ) $ do
              dropN @2; push True -- set to True due to fail operation

      , #cToken_transfer_type /-> do
          getField #ttContractAddress
          contractCalling @FA2.Parameter (Call @"Transfer")
          ifSome (do
              swap; toField #ttTransferList
              push zeroMutez; swap
              transferTokens
              dip swap; cons; swap
            ) $ do
              dropN @2; push True
      )

  if Holds then do
    -- drop; nil
    -- TODO: [#87] Improve handling of failed proposals
    failCustomNoArg #fAIL_DECISION_LAMBDA
  else
    nop

extraEntrypoints
  :: forall store ce pm s. (DAO.StorageC store ce pm)
  => TreasuryDaoExtraInterface : store : s
  :-> List Operation : store : s
extraEntrypoints =
  entryCase (Proxy @TreasuryDaoCustomEntrypointsKind)
    ( #cDefault /-> do
        doc $ DDescription "Entrypoint used for transferring money to the contract."
        ensureNotMigrated
        nil
    , #cNone /-> do
        -- Needed due to cannot declare 1 sum type.
        nil
    )

config :: DAO.Config TreasuryDaoContractExtra TreasuryDaoProposalMetadata TreasuryDaoExtraInterface
config = DAO.defaultConfig
  { DAO.cDaoName = "Treasury DAO"
  , DAO.cDaoDescription = treasuryDaoDoc
  , DAO.cProposalCheck = treasuryDaoProposalCheck
  , DAO.cRejectedProposalReturnValue = treasuryDaoRejectedProposalReturnValue
  , DAO.cDecisionLambda = decisionLambda
  , DAO.cCustomCall = extraEntrypoints

  , DAO.cMaxVotingPeriod = 60 * 60 * 24 * 30 -- 1 months
  , DAO.cMinVotingPeriod = 1 -- value between 1 second - 1 month

  , DAO.cMaxQuorumThreshold = 1000
  , DAO.cMinQuorumThreshold = 1

  , DAO.cMaxVotes = 1000
  , DAO.cMaxProposals = 500
  }

treasuryDaoContract ::
  ( DAO.DaoC
      TreasuryDaoContractExtra
      TreasuryDaoProposalMetadata TreasuryDaoExtraInterface
  ) => Contract
      (DAO.Parameter TreasuryDaoProposalMetadata TreasuryDaoExtraInterface)
      (DAO.Storage TreasuryDaoContractExtra TreasuryDaoProposalMetadata)
treasuryDaoContract = DAO.baseDaoContract config

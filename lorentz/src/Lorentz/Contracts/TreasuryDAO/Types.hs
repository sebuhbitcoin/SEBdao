-- SPDX-FileCopyrightText: 2021 TQ Tezos
-- SPDX-License-Identifier: LicenseRef-MIT-TQ
{-# OPTIONS_GHC -Wno-orphans #-}

-- | TreasuryDAO Types
module Lorentz.Contracts.TreasuryDAO.Types
  ( AgoraPostId (..)
  , TreasuryDaoContractExtra (..)
  , TreasuryDaoCustomEntrypointsKind
  , TreasuryDaoExtraInterface (..)
  , TreasuryDaoProposalMetadata (..)
  ) where

import Lorentz

import qualified Lorentz.Contracts.BaseDAO.Common.Types as DAO
import qualified Lorentz.Contracts.BaseDAO.Types as DAO

-- | TreasuryDAO has mainly configuration fields.
data TreasuryDaoContractExtra = TreasuryDaoContractExtra
  { ceFrozenScaleValue :: Natural
  , ceFrozenExtraValue :: Natural
  , ceSlashScaleValue :: Natural
  , ceSlashDivisionValue :: Natural
  , ceMinXtzAmount :: Mutez
  , ceMaxXtzAmount :: Mutez
  , ceMaxProposalSize :: Natural
  }
  deriving stock (Generic)
  deriving anyclass (IsoValue)

instance HasAnnotation TreasuryDaoContractExtra where
  annOptions = DAO.baseDaoAnnOptions

instance TypeHasDoc TreasuryDaoContractExtra where
  typeDocMdDescription = "Describe TreasuryDAO's extra fields in storage. \
    \They are mainly configuration fields."

instance Default TreasuryDaoContractExtra where
  def = TreasuryDaoContractExtra
    { ceFrozenScaleValue = 1
    , ceFrozenExtraValue = 0
    , ceSlashScaleValue = 1
    , ceSlashDivisionValue = 1
    , ceMinXtzAmount = toMutez 1
    , ceMaxXtzAmount = toMutez 10000
    , ceMaxProposalSize = 1000
    }

-- | A Treasury DAO proposal, contains list of transfers of 2 types:
-- Token transfer and Xtz transfer
data TreasuryDaoProposalMetadata = TreasuryDaoProposalMetadata
  { npAgoraPostId :: AgoraPostId
  , npTransfers :: [DAO.TransferType]
  }
  deriving stock (Generic)
  deriving anyclass (IsoValue)

instance HasAnnotation TreasuryDaoProposalMetadata where
  annOptions = DAO.baseDaoAnnOptions

instance TypeHasDoc TreasuryDaoProposalMetadata where
  typeDocMdDescription =
    "A treasury proposal which contains an Agora post ID and a list of transfer items."

newtype AgoraPostId = AgoraPostId Natural
  deriving stock (Generic)
  deriving anyclass (IsoValue)

instance HasAnnotation AgoraPostId where
  annOptions = DAO.baseDaoAnnOptions

instance TypeHasDoc AgoraPostId where
  typeDocMdDescription = "Describe an Agora post ID."


data TreasuryDaoExtraInterface
  = Default
  | None -- Not needed
  deriving stock (Generic)
  deriving anyclass (IsoValue, HasAnnotation)


instance TypeHasDoc TreasuryDaoExtraInterface where
  typeDocMdDescription = "Additional entrypoints of Game DAO."

instance ParameterHasEntrypoints TreasuryDaoExtraInterface where
  type ParameterEntrypointsDerivation TreasuryDaoExtraInterface = EpdPlain

data TreasuryDaoCustomEntrypointsKind
instance EntrypointKindHasDoc TreasuryDaoCustomEntrypointsKind where
  entrypointKindPos = 1065
  entrypointKindSectionName = "TreasuryDAO custom entrypoints"
  entrypointKindSectionDescription = Just
    "Some functionality specific to Treasury DAO. \
    \This demonstrates that we can e.g. add a `%default` entrypoint used to send \
    \mutez to the contract."


type instance ErrorArg "fAIL_DECISION_LAMBDA" = NoErrorArg

instance CustomErrorHasDoc "fAIL_DECISION_LAMBDA" where
  customErrClass = ErrClassActionException
  customErrDocMdCause = "Trying to execute decision lambda but result in errors."

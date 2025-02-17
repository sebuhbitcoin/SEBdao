-- SPDX-FileCopyrightText: 2021 TQ Tezos
-- SPDX-License-Identifier: LicenseRef-MIT-TQ

module Test.BaseDAO.Token
  ( test_BaseDAO_Token
  ) where

import Universum

import Lorentz hiding ((>>))
import Morley.Nettest
import Morley.Nettest.Tasty (nettestScenario)
import Test.Tasty (TestTree, testGroup)
import Util.Named

import qualified Lorentz.Contracts.BaseDAO.Types as DAO
import qualified Lorentz.Contracts.Spec.FA2Interface as FA2
import Test.BaseDAO.Common

{-# ANN module ("HLint: ignore Reduce duplication" :: Text) #-}

test_BaseDAO_Token :: TestTree
test_BaseDAO_Token = testGroup "BaseDAO non-FA2 token tests:"
  [ nettestScenario "can burn tokens from any accounts"
      $ uncapsNettest $ burnScenario
        $ originateTrivialDaoWithBalance
          (\o1 o2 ->
              [ ((o1, DAO.unfrozenTokenId), 10)
              , ((o1, DAO.frozenTokenId), 10)
              , ((o2, DAO.unfrozenTokenId), 10) -- for total supply
              , ((o2, DAO.frozenTokenId), 10) -- for total supply
              ]
          )
  , nettestScenario "can mint tokens to any accounts"
      $ uncapsNettest $ mintScenario
        $ originateTrivialDaoWithBalance
          (\o1 _ ->
              [ ((o1, DAO.unfrozenTokenId), 0)
              , ((o1, DAO.frozenTokenId), 0)
              ]
          )
  , nettestScenario "can call transfer tokens entrypoint"
      $ uncapsNettest $ transferContractTokensScenario originateTrivialDao
  ]

--------------------------------------------------------------------------------
-- Scenarios
--------------------------------------------------------------------------------

burnScenario
  :: forall caps base m param pm
  . (MonadNettest caps base m, FA2.ParameterC param, DAO.ParameterC param pm, HasCallStack)
  => OriginateFn param m -> m ()
burnScenario originateFn = withFrozenCallStack $ do
  ((owner1, _), _, dao, admin) <- originateFn

  withSender (AddressResolved owner1) $
    call dao (Call @"Burn") (DAO.BurnParam owner1 DAO.unfrozenTokenId 10)
    & expectCustomErrorNoArg #nOT_ADMIN dao

  withSender (AddressResolved admin) $ do
    call dao (Call @"Burn") (DAO.BurnParam owner1 DAO.unfrozenTokenId 11)
      & expectCustomError #fA2_INSUFFICIENT_BALANCE dao (#required .! 11, #present .! 10)

    call dao (Call @"Burn") (DAO.BurnParam owner1 DAO.frozenTokenId 11)
      & expectCustomError #fA2_INSUFFICIENT_BALANCE dao (#required .! 11, #present .! 10)

    call dao (Call @"Burn") (DAO.BurnParam owner1 DAO.unfrozenTokenId 10)
  checkTokenBalance (DAO.unfrozenTokenId) dao owner1 0
  withSender (AddressResolved admin) $
    call dao (Call @"Burn") (DAO.BurnParam owner1 DAO.frozenTokenId 5)
  checkTokenBalance (DAO.frozenTokenId) dao owner1 5

  -- Check total supply
  withSender (AddressResolved owner1) $
    call dao (Call @"Get_total_supply") (mkVoid DAO.unfrozenTokenId)
      & expectError dao (VoidResult (10 :: Natural)) -- initial = 20

  withSender (AddressResolved owner1) $
    call dao (Call @"Get_total_supply") (mkVoid DAO.frozenTokenId)
      & expectError dao (VoidResult (15 :: Natural)) -- initial = 20

mintScenario
  :: forall caps base m param pm
  . (MonadNettest caps base m, FA2.ParameterC param, DAO.ParameterC param pm, HasCallStack)
  => OriginateFn param m -> m ()
mintScenario originateFn = withFrozenCallStack $ do
  ((owner1, _), _, dao, admin) <- originateFn

  withSender (AddressResolved owner1) $
    call dao (Call @"Mint") (DAO.MintParam owner1 DAO.unfrozenTokenId 10)
    & expectCustomErrorNoArg #nOT_ADMIN dao

  withSender (AddressResolved admin) $ do
    call dao (Call @"Mint") (DAO.MintParam owner1 DAO.unfrozenTokenId 100)
  checkTokenBalance (DAO.unfrozenTokenId) dao owner1 100
  withSender (AddressResolved admin) $
    call dao (Call @"Mint") (DAO.MintParam owner1 DAO.frozenTokenId 50)
  checkTokenBalance (DAO.frozenTokenId) dao owner1 50

  -- Check total supply
  withSender (AddressResolved owner1) $
    call dao (Call @"Get_total_supply") (mkVoid DAO.unfrozenTokenId)
      & expectError dao (VoidResult (100 :: Natural)) -- initial = 0

  withSender (AddressResolved owner1) $
    call dao (Call @"Get_total_supply") (mkVoid DAO.frozenTokenId)
      & expectError dao (VoidResult (50 :: Natural)) -- initial = 0

transferContractTokensScenario
  :: forall caps base m param pm
  . (MonadNettest caps base m, FA2.ParameterC param, DAO.ParameterC param pm)
  => OriginateFn param m -> m ()
transferContractTokensScenario originateFn = do
  ((owner1, _), _, dao, admin) <- originateFn
  ((target_owner1, _), (target_owner2, _), fa2Contract, _) <- originateFn
  let addParams = FA2.OperatorParam
        { opOwner = target_owner1
        , opOperator = toAddress dao
        , opTokenId = DAO.unfrozenTokenId
        }
  withSender (AddressResolved target_owner1) $
    call fa2Contract (Call @"Update_operators") [FA2.AddOperator addParams]

  let transferParams = [ FA2.TransferItem
            { tiFrom = target_owner1
            , tiTxs = [ FA2.TransferDestination
                { tdTo = target_owner2
                , tdTokenId = DAO.unfrozenTokenId
                , tdAmount = 10
                } ]
            } ]
      param = DAO.TransferContractTokensParam
        { DAO.tcContractAddress = toAddress fa2Contract
        , DAO.tcParams = transferParams
        }

  withSender (AddressResolved owner1) $
    call dao (Call @"Transfer_contract_tokens") param
    & expectCustomErrorNoArg #nOT_ADMIN dao

  withSender (AddressResolved admin) $
    call dao (Call @"Transfer_contract_tokens") param
  checkTokenBalance (DAO.unfrozenTokenId) fa2Contract target_owner1 90
  checkTokenBalance (DAO.unfrozenTokenId) fa2Contract target_owner2 110

-- SPDX-FileCopyrightText: 2020 TQ Tezos
-- SPDX-License-Identifier: LicenseRef-MIT-TQ

module Test.Integrational.Common
  ( lOriginateBaseDao
  ) where

import Universum

import qualified Data.Map as M
import Data.List.NonEmpty ((!!))
import qualified Data.Set as S
import Lorentz
import Lorentz.Test
import Named (defaults, (!))
import Util.Named ((.!))

import qualified Lorentz.Contracts.BaseDAO as DAO
import Lorentz.Contracts.BaseDAO.Types

lOriginateBaseDao
  :: forall pm ce.
     ( NiceStorage (Storage ce pm), NiceParameterFull (Parameter pm), NiceStorage pm
     , TypeHasDoc pm, NicePackedValue pm
     , KnownValue ce, TypeHasDoc ce
     )
  => ce
  -> DAO.Config ce pm
  -> IntegrationalScenarioM ((Address, Address), (Address, Address), TAddress (DAO.Parameter pm), Address)
lOriginateBaseDao contractExtra config = do
  let
    owner1 = genesisAddresses !! 2
    operator1 = genesisAddresses !! 3
    owner2 = genesisAddresses !! 4
    operator2 = genesisAddresses !! 5
    admin = genesisAddresses !! 6

    balFunc = (\owner1_ owner2_ ->
        [ ((owner1_, unfrozenTokenId), 100)
        , ((owner2_, unfrozenTokenId), 100)
        ]
      )
    bal = M.fromList $ balFunc owner1 owner2

    operators = M.fromSet (const ()) $ S.fromList
        [ (#owner .! owner1, #operator .! operator1)
        , (#owner .! owner2, #operator .! operator2)
        ]
    storage = (mkStorage ! #admin admin ! #extra contractExtra ! defaults)
        { sLedger = BigMap bal
        , sOperators = BigMap operators
        }

  dao <- lOriginate (DAO.baseDaoContract config) "BaseDAO" storage (toMutez 0)
  pure ((owner1, operator1), (owner2, operator2), dao, admin)

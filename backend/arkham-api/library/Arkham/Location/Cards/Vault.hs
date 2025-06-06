module Arkham.Location.Cards.Vault (vault) where

import Arkham.Ability
import Arkham.GameValue
import Arkham.Helpers.Modifiers
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted
import Arkham.Matcher
import Arkham.Scenarios.ForTheGreaterGood.Helpers

newtype Vault = Vault LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

vault :: LocationCard Vault
vault = location Vault Cards.vault 4 (PerPlayer 1)

instance HasModifiersFor Vault where
  getModifiersFor (Vault attrs) = whenUnrevealed attrs do
    modifySelect attrs (not_ $ InvestigatorWithTokenKey #elderthing) [CannotEnter (toId attrs)]

instance HasAbilities Vault where
  getAbilities (Vault a) =
    extendRevealed1 a $ mkAbility a 1 $ forced $ RevealLocation #after You (be a)

instance RunMessage Vault where
  runMessage msg l@(Vault attrs) = runQueueT $ case msg of
    UseThisAbility _ (isSource attrs -> True) 1 -> do
      mKey <- getRandomKey
      for_ mKey (placeKey attrs)
      pure l
    _ -> Vault <$> liftRunMessage msg attrs

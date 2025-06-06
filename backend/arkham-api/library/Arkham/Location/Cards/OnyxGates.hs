module Arkham.Location.Cards.OnyxGates (onyxGates) where

import Arkham.Ability
import Arkham.Campaigns.TheDreamEaters.Key
import Arkham.Helpers.GameValue (perPlayer)
import Arkham.Helpers.Modifiers (ModifierType (..), modifySelf)
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted
import Arkham.Matcher
import Arkham.Message.Lifted.Log

newtype OnyxGates = OnyxGates LocationAttrs
  deriving anyclass IsLocation
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

onyxGates :: LocationCard OnyxGates
onyxGates = location OnyxGates Cards.onyxGates 1 (Static 12)

instance HasModifiersFor OnyxGates where
  getModifiersFor (OnyxGates attrs) = do
    n <- perPlayer 1
    modifySelf attrs [ShroudModifier n]

instance HasAbilities OnyxGates where
  getAbilities (OnyxGates attrs) =
    extendRevealed
      attrs
      [ restrictedAbility attrs 1 (hasCampaignCount EvidenceOfKadath $ atLeast 1)
          $ forced
          $ RevealLocation #after Anyone
          $ be attrs
      ]

instance RunMessage OnyxGates where
  runMessage msg l@(OnyxGates attrs) = runQueueT $ case msg of
    UseThisAbility _ (isSource attrs -> True) 1 -> do
      n <- getRecordCount EvidenceOfKadath
      when (n > 0) (removeTokens (attrs.ability 1) attrs #clue n)
      pure l
    _ -> OnyxGates <$> liftRunMessage msg attrs

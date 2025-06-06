module Arkham.Asset.Assets.Charisma3 (charisma3) where

import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Card
import Arkham.Slot

newtype Charisma3 = Charisma3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

charisma3 :: AssetCard Charisma3
charisma3 = asset Charisma3 Cards.charisma3

slot :: AssetAttrs -> Slot
slot attrs = Slot (toSource attrs) []

instance RunMessage Charisma3 where
  runMessage msg (Charisma3 attrs) = runQueueT $ case msg of
    -- Slots need to be added before the asset is played so we hook into played card
    CardIsEnteringPlay iid card | toCardId card == toCardId attrs -> do
      push $ AddSlot iid #ally (slot attrs)
      Charisma3 <$> liftRunMessage msg attrs
    _ -> Charisma3 <$> liftRunMessage msg attrs

module Arkham.Location.Cards.ArkhamWoodsOldHouse (arkhamWoodsOldHouse) where

import Arkham.GameValue
import Arkham.Location.Cards qualified as Cards
import Arkham.Location.Import.Lifted

newtype ArkhamWoodsOldHouse = ArkhamWoodsOldHouse LocationAttrs
  deriving anyclass (IsLocation, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

arkhamWoodsOldHouse :: LocationCard ArkhamWoodsOldHouse
arkhamWoodsOldHouse =
  locationWith
    ArkhamWoodsOldHouse
    Cards.arkhamWoodsOldHouse
    2
    (PerPlayer 1)
    (investigateSkillL .~ #willpower)

instance RunMessage ArkhamWoodsOldHouse where
  runMessage msg (ArkhamWoodsOldHouse attrs) = ArkhamWoodsOldHouse <$> runMessage msg attrs

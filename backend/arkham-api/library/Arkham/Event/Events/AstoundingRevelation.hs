module Arkham.Event.Events.AstoundingRevelation (astoundingRevelation) where

import Arkham.Ability
import Arkham.Asset.Uses
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Import.Lifted
import Arkham.Matcher
import Arkham.Trait

newtype AstoundingRevelation = AstoundingRevelation EventAttrs
  deriving anyclass (IsEvent, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

astoundingRevelation :: EventCard AstoundingRevelation
astoundingRevelation = event AstoundingRevelation Cards.astoundingRevelation

instance HasAbilities AstoundingRevelation where
  getAbilities (AstoundingRevelation x) =
    [ playerLimit (PerSearch Research)
        $ mkAbility x 1
        $ triggered (AmongSearchedCards You) (DiscardCost FromDeck $ SearchedCardTarget x.cardId)
    ]

instance RunMessage AstoundingRevelation where
  runMessage msg e@(AstoundingRevelation attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      secretAssets <- select $ assetControlledBy iid <> AssetWithUseType Secret
      chooseOneM iid do
        resourceLabeled iid $ gainResources iid (attrs.ability 1) 2
        targets secretAssets \aid -> addUses (attrs.ability 1) aid Secret 1
      pure e
    _ -> AstoundingRevelation <$> liftRunMessage msg attrs

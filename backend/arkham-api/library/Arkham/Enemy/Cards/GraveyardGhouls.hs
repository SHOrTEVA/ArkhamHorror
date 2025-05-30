module Arkham.Enemy.Cards.GraveyardGhouls (graveyardGhouls) where

import Arkham.Enemy.Cards qualified as Cards
import Arkham.Enemy.Import.Lifted
import Arkham.Helpers.Modifiers
import Arkham.Matcher

newtype GraveyardGhouls = GraveyardGhouls EnemyAttrs
  deriving anyclass IsEnemy
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, HasAbilities)

graveyardGhouls :: EnemyCard GraveyardGhouls
graveyardGhouls =
  enemyWith
    GraveyardGhouls
    Cards.graveyardGhouls
    (3, Static 3, 2)
    (1, 1)
    (\a -> a & preyL .~ BearerOf (toId a))

instance HasModifiersFor GraveyardGhouls where
  getModifiersFor (GraveyardGhouls a) =
    modifySelect a (investigatorEngagedWith a) [CardsCannotLeaveYourDiscardPile]

instance RunMessage GraveyardGhouls where
  runMessage msg (GraveyardGhouls attrs) = GraveyardGhouls <$> runMessage msg attrs

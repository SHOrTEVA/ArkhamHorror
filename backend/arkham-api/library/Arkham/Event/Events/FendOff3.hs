module Arkham.Event.Events.FendOff3 (fendOff3) where

import Arkham.Enemy.Types (Field (..))
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Import.Lifted
import Arkham.Helpers.Modifiers (ModifierType (..), modified_)
import Arkham.Helpers.Window (spawnedEnemy)
import Arkham.Projection

newtype FendOff3 = FendOff3 EventAttrs
  deriving anyclass (IsEvent, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

fendOff3 :: EventCard FendOff3
fendOff3 = event FendOff3 Cards.fendOff3

instance HasModifiersFor FendOff3 where
  getModifiersFor (FendOff3 attrs) = case attrs.placement of
    AttachedToEnemy eid -> modified_ attrs eid [CannotReady]
    _ -> pure mempty

instance RunMessage FendOff3 where
  runMessage msg e@(FendOff3 attrs) = runQueueT $ case msg of
    PlayThisEvent iid (is attrs -> True) -> do
      let enemy = spawnedEnemy attrs.windows
      card <- field EnemyCard enemy
      focusCards [card] $ initiateEnemyAttackWith enemy attrs iid (`andThen` DoStep 1 msg)
      pure e
    DoStep 1 (PlayThisEvent iid (is attrs -> True)) -> do
      let enemy = spawnedEnemy attrs.windows
      automaticallyEvadeEnemy iid enemy
      place attrs (AttachedToEnemy enemy)
      pure e
    _ -> FendOff3 <$> liftRunMessage msg attrs

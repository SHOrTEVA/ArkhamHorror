module Arkham.Event.Events.IveGotAPlan (iveGotAPlan) where

import Arkham.Aspect hiding (aspect)
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Import.Lifted
import Arkham.Fight
import Arkham.Investigator.Types (Field (..))
import Arkham.Modifier

newtype IveGotAPlan = IveGotAPlan EventAttrs
  deriving anyclass (IsEvent, HasAbilities, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

iveGotAPlan :: EventCard IveGotAPlan
iveGotAPlan = event IveGotAPlan Cards.iveGotAPlan

instance RunMessage IveGotAPlan where
  runMessage msg e@(IveGotAPlan attrs) = runQueueT $ case msg of
    PlayThisEvent iid (is attrs -> True) -> do
      sid <- getRandom
      skillTestModifier sid attrs iid
        $ ForEach
          (MaxCalculation (Fixed 3) (InvestigatorFieldCalculation iid InvestigatorClues))
          [DamageDealt 1]
      aspect iid attrs (#intellect `InsteadOf` #combat) (mkChooseFight sid iid attrs)
      pure e
    _ -> IveGotAPlan <$> liftRunMessage msg attrs

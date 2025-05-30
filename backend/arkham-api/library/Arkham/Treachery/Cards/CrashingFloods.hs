module Arkham.Treachery.Cards.CrashingFloods (crashingFloods) where

import Arkham.Agenda.Sequence qualified as AS
import Arkham.Agenda.Types (Field (AgendaSequence))
import Arkham.Classes.HasGame
import Arkham.Id
import Arkham.Matcher
import Arkham.Projection
import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Import.Lifted

newtype CrashingFloods = CrashingFloods TreacheryAttrs
  deriving anyclass (IsTreachery, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

crashingFloods :: TreacheryCard CrashingFloods
crashingFloods = treachery CrashingFloods Cards.crashingFloods

getStep :: HasGame m => Maybe AgendaId -> m Int
getStep Nothing = pure 3 -- if no agenda than act is 3
getStep (Just agenda) = do
  side <- fieldMap AgendaSequence AS.agendaStep agenda
  case side of
    AS.AgendaStep step -> pure step

instance RunMessage CrashingFloods where
  runMessage msg t@(CrashingFloods attrs) = runQueueT $ case msg of
    Revelation iid (isSource attrs -> True) -> do
      sid <- getRandom
      revelationSkillTest sid iid attrs #agility (Fixed 3)
      pure t
    FailedThisSkillTest iid (isSource attrs -> True) -> do
      n <- getStep =<< selectOne (AgendaWithSide AS.A)
      assignDamage iid attrs n
      loseActions iid attrs n
      pure t
    _ -> CrashingFloods <$> liftRunMessage msg attrs

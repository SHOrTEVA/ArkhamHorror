module Arkham.Treachery.Cards.PsychopompsSongUnionAndDisillusion (psychopompsSongUnionAndDisillusion) where

import Arkham.Treachery.Cards qualified as Cards
import Arkham.Treachery.Cards.PsychopompsSong
import Arkham.Treachery.Import.Lifted

newtype PsychopompsSongUnionAndDisillusion = PsychopompsSongUnionAndDisillusion PsychopompsSong
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity, IsTreachery, HasModifiersFor, HasAbilities)

psychopompsSongUnionAndDisillusion :: TreacheryCard PsychopompsSongUnionAndDisillusion
psychopompsSongUnionAndDisillusion =
  treachery
    (PsychopompsSongUnionAndDisillusion . PsychopompsSong)
    Cards.psychopompsSongUnionAndDisillusion

instance RunMessage PsychopompsSongUnionAndDisillusion where
  runMessage msg (PsychopompsSongUnionAndDisillusion inner) =
    PsychopompsSongUnionAndDisillusion <$> runMessage msg inner

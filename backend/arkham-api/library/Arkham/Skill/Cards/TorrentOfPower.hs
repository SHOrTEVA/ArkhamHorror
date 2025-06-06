module Arkham.Skill.Cards.TorrentOfPower (torrentOfPower) where

import Arkham.Asset.Uses
import Arkham.Calculation
import Arkham.Cost
import {-# SOURCE #-} Arkham.GameEnv
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.Skill.Cards qualified as Cards
import Arkham.Skill.Import.Lifted

newtype TorrentOfPower = TorrentOfPower SkillAttrs
  deriving anyclass (IsSkill, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

torrentOfPower :: SkillCard TorrentOfPower
torrentOfPower =
  skillWith TorrentOfPower Cards.torrentOfPower
    $ additionalCostL
    ?~ UpTo (Fixed 3) (UseCost (AssetControlledBy You) Charge 1)

chargesSpent :: Payment -> Int
chargesSpent (Payments xs) = sum $ map chargesSpent xs
chargesSpent (UsesPayment n) = n
chargesSpent _ = 0

instance HasModifiersFor TorrentOfPower where
  getModifiersFor (TorrentOfPower attrs) = do
    mSkillTest <- getSkillTest
    case mSkillTest of
      Just _ -> do
        let n = maybe 0 chargesSpent (skillAdditionalPayment attrs)
        modified_ attrs attrs.cardId [AddSkillIcons $ cycleN n [#willpower, #wild]]
      _ -> pure mempty

instance RunMessage TorrentOfPower where
  runMessage msg (TorrentOfPower attrs) = TorrentOfPower <$> runMessage msg attrs

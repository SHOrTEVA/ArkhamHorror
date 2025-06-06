module Arkham.Asset.Assets.SixthSense4 (sixthSense4, sixthSense4Effect) where

import Arkham.Ability
import Arkham.Aspect hiding (aspect)
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.ChaosToken
import Arkham.Effect.Import
import Arkham.Helpers.Cost
import Arkham.Helpers.Location
import Arkham.Helpers.Modifiers hiding (skillTestModifier)
import Arkham.Helpers.SkillTest.Target
import Arkham.Investigate
import Arkham.Location.Types (Field (..))
import Arkham.Matcher hiding (RevealChaosToken)
import Arkham.Message.Lifted.Choose
import Arkham.Projection
import Arkham.Window qualified as Window

newtype SixthSense4 = SixthSense4 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sixthSense4 :: AssetCard SixthSense4
sixthSense4 = asset SixthSense4 Cards.sixthSense4

instance HasAbilities SixthSense4 where
  getAbilities (SixthSense4 a) = [investigateAbility a 1 mempty ControlsThis]

instance RunMessage SixthSense4 where
  runMessage msg a@(SixthSense4 attrs) = runQueueT $ case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      withLocationOf iid \lid -> do
        let source = attrs.ability 1
        sid <- getRandom
        createCardEffect Cards.sixthSense4 (effectMetaTarget sid) source (InvestigationTarget iid lid)
        skillTestModifier sid source iid (SkillModifier #willpower 2)
        aspect iid source (#willpower `InsteadOf` #intellect) (mkInvestigate sid iid source)
      pure a
    _ -> SixthSense4 <$> liftRunMessage msg attrs

newtype SixthSense4Effect = SixthSense4Effect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

sixthSense4Effect :: EffectArgs -> SixthSense4Effect
sixthSense4Effect = cardEffect SixthSense4Effect Cards.sixthSense4

instance RunMessage SixthSense4Effect where
  runMessage msg e@(SixthSense4Effect attrs) = runQueueT $ case msg of
    RevealChaosToken (SkillTestSource sid) iid token | maybe False (isTarget sid) attrs.metaTarget -> do
      push $ If (Window.RevealChaosTokenEffect iid token attrs.id) [DoStep 1 msg]
      disable attrs
      pure e
    DoStep 1 (RevealChaosToken (SkillTestSource sid) iid token) | maybe False (isTarget sid) attrs.metaTarget -> do
      case attrs.target of
        InvestigationTarget iid' lid | iid == iid' -> do
          when (token.face `elem` [Skull, Cultist, Tablet, ElderThing]) do
            currentShroud <- fieldJust LocationShroud lid
            locations <-
              selectWithField
                LocationShroud
                (LocationWithDistanceFromAtMost 2 (locationWithInvestigator iid) RevealedLocation)
                <&> mapMaybe (\(loc, mshroud) -> (loc,) <$> mshroud)

            locationsWithAdditionalCosts <- forMaybeM locations \location@(lid', _) -> runMaybeT do
              guard $ lid /= lid'
              mods <- getModifiers lid'
              let costs = fold [m | AdditionalCostToInvestigate m <- mods]
              liftGuardM $ getCanAffordCost iid attrs [#investigate] [] costs
              pure (location, costs)
            batchId <- getRandom
            currentTarget <- fromMaybe (toTarget lid) <$> getSkillTestTarget
            chooseOneM iid do
              labeled "Do not choose other location" nothing
              for_ locationsWithAdditionalCosts \((location, shroud), cost) -> do
                targeting location do
                  batching batchId do
                    push $ PayAdditionalCost iid batchId cost
                    push $ SetSkillTestTarget (BothTarget (toTarget location) currentTarget)
                    chooseOneM iid do
                      labeled "Use new location's shroud" do
                        skillTestModifier sid attrs.source sid (SetDifficulty shroud)
                      labeled "Use original locations shroud" do
                        skillTestModifier sid attrs.source sid (SetDifficulty currentShroud)
        _ -> error "Invalid target"
      pure e
    SkillTestEnds sid _ _ | maybe False (isTarget sid) attrs.metaTarget -> disableReturn e
    _ -> SixthSense4Effect <$> liftRunMessage msg attrs

module Arkham.Asset.Assets.GuidedByTheUnseen3 (guidedByTheUnseen3) where

import Arkham.Ability hiding (you)
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Import.Lifted
import Arkham.Asset.Uses
import Arkham.Capability
import Arkham.Card
import Arkham.Helpers.SkillTest (getIsCommittable, getSkillTestInvestigator, withSkillTest)
import Arkham.Matcher
import Arkham.Message.Lifted.Choose
import Arkham.Modifier
import Arkham.Strategy

newtype GuidedByTheUnseen3 = GuidedByTheUnseen3 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

guidedByTheUnseen3 :: AssetCard GuidedByTheUnseen3
guidedByTheUnseen3 = asset GuidedByTheUnseen3 Cards.guidedByTheUnseen3

instance HasAbilities GuidedByTheUnseen3 where
  getAbilities (GuidedByTheUnseen3 x) =
    [ playerLimit PerTestOrAbility
        $ controlled
          x
          1
          ( DuringSkillTest
              $ SkillTestAtYourLocation
              <> SkillTestOfInvestigator (oneOf [can.search.deck, can.manipulate.deck])
          )
        $ FastAbility Free
    ]

instance RunMessage GuidedByTheUnseen3 where
  runMessage msg a@(GuidedByTheUnseen3 attrs) = runQueueT $ case msg of
    UseThisAbility you (isSource attrs -> True) 1 -> do
      iid <- fromJustNote "not skill test" <$> getSkillTestInvestigator
      canSearchDeck <- can.search.deck iid
      if canSearchDeck
        then search you (attrs.ability 1) iid [fromTopOfDeck 3] #any (defer attrs IsNotDraw)
        else whenM (can.shuffle.deck iid) $ shuffleDeck iid
      pure a
    SearchFound iid (isTarget attrs -> True) _ cards | notNull cards -> do
      hasKingInYellow <- selectAny $ assetControlledBy iid <> assetIs Cards.theKingInYellow
      committable <- if hasKingInYellow
        then pure []
        else filterM (getIsCommittable iid) cards
      focusCards cards do
        if attrs.use Secret == 0 || null committable
          then continue_ iid
          else withSkillTest \sid ->
            -- MustBeCommitted prevents being able to uncommit, as it is really "committed"
            chooseOneM iid do
              labeled "Do not commit any cards" unfocusCards
              targets committable \card -> do
                unfocusCards
                push $ SpendUses (attrs.ability 1) (toTarget attrs) Secret 1
                skillTestModifier sid attrs (toCardId card) MustBeCommitted
                push $ SkillTestCommitCard iid card
      pure a
    _ -> GuidedByTheUnseen3 <$> liftRunMessage msg attrs

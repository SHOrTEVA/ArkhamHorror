module Arkham.Event.Events.OneTwoPunch (oneTwoPunch, OneTwoPunch (..)) where

import Arkham.Classes
import Arkham.Event.Cards qualified as Cards
import Arkham.Event.Runner
import Arkham.Fight
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.Prelude
import Arkham.SkillTest.Base

newtype Metadata = Metadata {isFirst :: Bool}
  deriving stock (Show, Eq, Generic)
  deriving anyclass (ToJSON, FromJSON)

newtype OneTwoPunch = OneTwoPunch (EventAttrs `With` Metadata)
  deriving anyclass (IsEvent, HasModifiersFor, HasAbilities)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

oneTwoPunch :: EventCard OneTwoPunch
oneTwoPunch = event (OneTwoPunch . (`with` Metadata True)) Cards.oneTwoPunch

instance RunMessage OneTwoPunch where
  runMessage msg e@(OneTwoPunch (attrs `With` metadata)) = case msg of
    PlayThisEvent iid eid | eid == toId attrs -> do
      sid <- getRandom
      chooseFight <- toMessage <$> mkChooseFight sid iid attrs
      enabled <- skillTestModifier sid attrs iid (SkillModifier #combat 1)
      pushAll [enabled, chooseFight]
      pure e
    PassedThisSkillTest iid (isSource attrs -> True) | isFirst metadata -> do
      skillTest <- fromJustNote "invalid call" <$> getSkillTest
      case skillTestTarget skillTest of
        EnemyTarget eid -> do
          isStillAlive <- selectAny $ EnemyWithId eid
          player <- getPlayer iid
          sid <- getRandom
          enabled <- skillTestModifiers sid attrs iid [SkillModifier #combat 2, DamageDealt 1]
          push
            $ chooseOrRunOne player
            $ [ Label
                "Fight that enemy again"
                [BeginSkillTestWithPreMessages' [enabled] (resetSkillTest sid skillTest)]
              | isStillAlive
              ]
            <> [Label "Do not fight that enemy again" []]
        LocationTarget lid -> do
          isStillAlive <- selectAny $ LocationWithId lid
          player <- getPlayer iid
          sid <- getRandom
          enabled <- skillTestModifiers sid attrs iid [SkillModifier #combat 2, DamageDealt 1]
          push
            $ chooseOrRunOne player
            $ [ Label
                "Fight that location again"
                [BeginSkillTestWithPreMessages' [enabled] (resetSkillTest sid skillTest)]
              | isStillAlive
              ]
            <> [Label "Do not fight that location again" []]
        other -> error $ "invalid call: " <> show other
      pure . OneTwoPunch $ attrs `with` Metadata False
    _ -> OneTwoPunch . (`with` metadata) <$> runMessage msg attrs

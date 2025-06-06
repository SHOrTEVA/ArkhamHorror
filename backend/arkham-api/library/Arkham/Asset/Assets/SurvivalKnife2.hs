module Arkham.Asset.Assets.SurvivalKnife2 (survivalKnife2) where

import Arkham.Ability
import Arkham.Asset.Cards qualified as Cards
import Arkham.Asset.Runner hiding (EnemyAttacks)
import Arkham.Attack
import Arkham.Fight
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.Prelude
import Arkham.Window (Window, windowType)
import Arkham.Window qualified as Window

newtype SurvivalKnife2 = SurvivalKnife2 AssetAttrs
  deriving anyclass (IsAsset, HasModifiersFor)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

survivalKnife2 :: AssetCard SurvivalKnife2
survivalKnife2 = asset SurvivalKnife2 Cards.survivalKnife2

instance HasAbilities SurvivalKnife2 where
  getAbilities (SurvivalKnife2 a) =
    [ fightAbility a 1 mempty ControlsThis
    , controlled a 2 (DuringPhase #enemy)
        $ triggered (EnemyAttacks #when You AnyEnemyAttack AnyEnemy) (exhaust a)
    ]

toEnemy :: [Window] -> EnemyId
toEnemy [] = error "called during incorrect window"
toEnemy ((windowType -> Window.EnemyAttacks details) : _) = attackEnemy details
toEnemy (_ : xs) = toEnemy xs

instance RunMessage SurvivalKnife2 where
  runMessage msg a@(SurvivalKnife2 attrs) = case msg of
    UseThisAbility iid (isSource attrs -> True) 1 -> do
      let source = toAbilitySource attrs 1
      sid <- getRandom
      chooseFight <- toMessage <$> mkChooseFight sid iid source
      enabled <- skillTestModifiers sid source iid [SkillModifier #combat 2]
      pushAll [enabled, chooseFight]
      pure a
    UseCardAbility iid (isSource attrs -> True) 2 (toEnemy -> enemy) _ -> do
      let source = toAbilitySource attrs 2
      sid <- getRandom
      enabled <- skillTestModifiers sid (attrs.ability 2) iid [SkillModifier #combat 2, DamageDealt 1]
      pushAll
        [ enabled
        , FightEnemy enemy $ mkChooseFightPure sid iid source
        ]
      pure a
    _ -> SurvivalKnife2 <$> runMessage msg attrs

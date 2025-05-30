module Arkham.Effect.Effects.EndOfRoundEffect (
  EndOfRoundEffect (..),
  endOfRoundEffect,
  endOfRoundEffect',
) where

import Arkham.Classes
import Arkham.Effect.Runner
import Arkham.Prelude

newtype EndOfRoundEffect = EndOfRoundEffect EffectAttrs
  deriving anyclass (HasAbilities, IsEffect)
  deriving newtype (Show, Eq, ToJSON, FromJSON, Entity)

endOfRoundEffect :: EffectArgs -> EndOfRoundEffect
endOfRoundEffect = EndOfRoundEffect . uncurry (baseAttrs "eoref")

endOfRoundEffect'
  :: EffectId
  -> Source
  -> [Message]
  -> EndOfRoundEffect
endOfRoundEffect' eid source msgs =
  EndOfRoundEffect
    $ EffectAttrs
      { effectId = eid
      , effectSource = source
      , effectTarget = GameTarget
      , effectCardCode = "eoref"
      , effectMetadata = Just (EffectMessages msgs)
      , effectTraits = mempty
      , effectWindow = Nothing
      , effectDisableWindow = Nothing
      , effectOnDisable = Nothing
      , effectFinished = False
      , effectExtraMetadata = Null
      , effectSkillTest = Nothing
      , effectCardId = Nothing
      , effectMetaKeys = []
      }

instance HasModifiersFor EndOfRoundEffect

instance RunMessage EndOfRoundEffect where
  runMessage msg e@(EndOfRoundEffect attrs) = runQueueT $ case msg of
    EndRound -> do
      case attrs.metadata of
        Just (EffectMessages msgs) -> push $ Priority $ Run $ DisableEffect attrs.id : msgs
        _ -> push $ Priority $ DisableEffect attrs.id
      pure e
    _ -> EndOfRoundEffect <$> liftRunMessage msg attrs

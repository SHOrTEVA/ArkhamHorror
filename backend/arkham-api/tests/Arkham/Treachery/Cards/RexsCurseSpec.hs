module Arkham.Treachery.Cards.RexsCurseSpec (spec) where

import Arkham.Calculation
import Arkham.Helpers.Modifiers
import Arkham.Matcher
import Arkham.SkillTest.Base
import Arkham.Treachery.Cards qualified as Cards
import TestImport.Lifted

spec :: Spec
spec = describe "Rex's Curse" $ do
  it "is put into play into your threat area" $ gameTest $ \investigator -> do
    rexsCurse <- genPlayerCard Cards.rexsCurse

    pushAndRunAll [loadDeck investigator [rexsCurse], drawCards (toId investigator) investigator 1]
    assert
      $ selectAny
      $ TreacheryInThreatAreaOf (InvestigatorWithId $ toId investigator)
      <> treacheryIs Cards.rexsCurse

  it "causes you to reveal another token" $ gameTest $ \investigator -> do
    updateInvestigator investigator (intellectL .~ 5)
    rexsCurse <- genPlayerCard Cards.rexsCurse

    didRunMessage <- didPassSkillTestBy investigator SkillIntellect 1

    sid <- getRandom
    pushAndRunAll
      [ SetChaosTokens [PlusOne]
      , loadDeck investigator [rexsCurse]
      , drawCards (toId investigator) investigator 1
      , BeginSkillTest
          $ initSkillTest
            sid
            (toId investigator)
            (TestSource mempty)
            TestTarget
            SkillIntellect
            (SkillTestDifficulty $ Fixed 5)
      ]
    chooseOnlyOption "start skill test"
    chooseOnlyOption "trigger rex's curse"
    chooseOnlyOption "apply results"
    assert
      $ selectAny
        ( TreacheryInThreatAreaOf (InvestigatorWithId $ toId investigator)
            <> treacheryIs Cards.rexsCurse
        )
    didRunMessage `refShouldBe` True

  it "is shuffled back into your deck if you fail the test" $ gameTest $ \investigator -> do
    updateInvestigator investigator (intellectL .~ 5)
    rexsCurse <- genPlayerCard Cards.rexsCurse
    -- need a second card in the deck to allow shuffling
    rexsCurse2 <- genPlayerCard Cards.rexsCurse
    sid <- getRandom
    pushAndRunAll
      [ SetChaosTokens [MinusOne]
      , loadDeck investigator [rexsCurse, rexsCurse2]
      , drawCards (toId investigator) investigator 1
      , beginSkillTest sid investigator SkillIntellect 4
      ]
    chooseOnlyOption "start skill test"
    -- we sneak in this modifier to cause the next test (with the same token) to fail instead
    pushAndRun
      =<< skillTestModifier
        sid
        (TestSource mempty)
        (toTarget investigator)
        (SkillModifier SkillIntellect (-1))
    chooseOnlyOption "trigger rex's curse"
    chooseOnlyOption "apply results"
    assert
      $ selectNone
      $ TreacheryInThreatAreaOf (InvestigatorWithId $ toId investigator)
      <> treacheryIs Cards.rexsCurse
    fieldAssert InvestigatorDeck ((== 2) . length) investigator

  it "remains in play if it cannot be shuffled into your deck" $ gameTest $ \investigator -> do
    updateInvestigator investigator (intellectL .~ 5)
    rexsCurse <- genPlayerCard Cards.rexsCurse
    sid <- getRandom
    pushAndRunAll
      [ SetChaosTokens [MinusOne]
      , loadDeck investigator [rexsCurse]
      , drawCards (toId investigator) investigator 1
      , beginSkillTest sid investigator SkillIntellect 4
      ]
    chooseOnlyOption "start skill test"
    -- we sneak in this modifier to cause the next test (with the same token) to fail instead
    pushAndRun
      =<< skillTestModifier
        sid
        (TestSource mempty)
        (toTarget investigator)
        (SkillModifier SkillIntellect (-1))
    chooseOnlyOption "trigger rex's curse"
    chooseOnlyOption "apply results"
    assert
      $ selectAny
      $ TreacheryInThreatAreaOf (InvestigatorWithId $ toId investigator)
      <> treacheryIs Cards.rexsCurse
    fieldAssert InvestigatorDeck null investigator

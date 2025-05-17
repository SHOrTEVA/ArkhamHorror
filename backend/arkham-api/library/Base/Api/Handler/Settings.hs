{-# LANGUAGE DuplicateRecordFields #-}

module Base.Api.Handler.Settings where

import Database.Esqueleto.Experimental
import Import hiding (update, (=.), (==.))
import Safe

newtype UserSettings = UserSettings {beta :: Bool}
  deriving stock (Generic)
  deriving anyclass (FromJSON)

betaSetting :: UserSettings -> Bool
betaSetting (UserSettings b) = b

data CurrentUser = CurrentUser
  { username :: Text
  , email :: Text
  , beta :: Bool
  }
  deriving stock (Generic)
  deriving anyclass (ToJSON)

newtype SiteSettings = SiteSettings
  { assetHost :: Maybe Text
  }

instance ToJSON SiteSettings where
  toJSON SiteSettings {assetHost} = object ["assetHost" .= assetHost]

getApiV1SiteSettingsR :: Handler SiteSettings
getApiV1SiteSettingsR = SiteSettings <$> getsApp (appAssetHost . appSettings)

putApiV1SettingsR :: Handler CurrentUser
putApiV1SettingsR = do
  userId <- fromJustNote "Not authenticated" <$> getRequestUserId
  settings <- requireCheckJsonBody
  runDB $ do
    update $ \u -> do
      set u [UserBeta =. val (betaSetting settings)]
      where_ $ u ^. UserId ==. val userId
    User {..} <- get404 userId
    pure $ CurrentUser userUsername userEmail userBeta

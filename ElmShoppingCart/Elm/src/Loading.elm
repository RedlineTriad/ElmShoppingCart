module Loading exposing (Loading(..), fromResult, isLoading, toLoading, toMaybe)


type Loading error value
    = NotAsked
    | Loading (Maybe value)
    | Failure error
    | Success value


toMaybe : Loading a b -> Maybe b
toMaybe loading =
    case loading of
        Loading a ->
            a

        Success value ->
            Just value

        _ ->
            Nothing


toLoading : Loading a b -> Loading a b
toLoading loading =
    case loading of
        Loading a ->
            Loading a

        Success value ->
            Loading (Just value)

        a ->
            a


fromResult : Result a b -> Loading a b
fromResult result =
    case result of
        Ok b ->
            Success b

        Err a ->
            Failure a


isLoading : Loading a b -> Bool
isLoading loading =
    case loading of
        Loading _ ->
            True

        _ ->
            False

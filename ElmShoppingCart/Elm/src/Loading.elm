module Loading exposing (Loading(..), toLoading, toMaybe)


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

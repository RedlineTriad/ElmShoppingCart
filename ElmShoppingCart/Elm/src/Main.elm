module Main exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Utilities.Spacing as Spacing
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (Decoder)
import Json.Decode.Extra as JDE
import Time exposing (..)



---- MODEL ----


type alias Model =
    { count : Int
    , weather : Maybe (List Weather)
    , loading : Bool
    }


type alias Weather =
    { date : Posix
    , temperatureC : Int
    , temperatureF : Int
    , summary : String
    }


init : ( Model, Cmd Msg )
init =
    ( { count = 0
      , weather = Nothing
      , loading = False
      }
    , Cmd.none
    )



---- UPDATE ----


type Msg
    = Increment
    | Decrement
    | GetText
    | GotText (Result Http.Error (List Weather))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Increment ->
            ( { model | count = model.count + 1 }, Cmd.none )

        Decrement ->
            ( { model | count = model.count - 1 }, Cmd.none )

        GetText ->
            ( { model | loading = True }, getWeatherForecast )

        GotText result ->
            case result of
                Ok newWeather ->
                    ( { model
                        | weather = Just newWeather
                        , loading = False
                      }
                    , Cmd.none
                    )

                Err err ->
                    ( { model
                        | loading = False
                      }
                    , Cmd.none
                    )



---- VIEW ----


view : Model -> Html Msg
view model =
    Grid.container []
        [ Grid.row []
            [ Grid.col []
                [ h1 []
                    [ text "Your Elm App is working!" ]
                ]
            ]
        , Grid.row []
            [ Grid.col []
                [ p [] [ text (String.fromInt model.count) ]
                , Button.button [ Button.primary, Button.attrs [ onClick Increment ] ] [ text "Increment" ]
                , Button.button [ Button.danger, Button.attrs [ onClick Decrement ] ] [ text "Decrement" ]
                ]
            , Grid.col []
                [ Button.button [ Button.primary, Button.attrs [ onClick GetText ] ] [ text "Get text" ]
                ]
            , Grid.col []
                (case model.weather of
                    Just weather ->
                        weather |> List.map viewWeather

                    Nothing ->
                        [ pre []
                            [ text
                                (if model.loading then
                                    "Loading..."

                                 else
                                    ""
                                )
                            ]
                        ]
                )
            ]
        ]


viewWeather : Weather -> Html msg
viewWeather weather =
    Card.config []
        |> Card.header [ class "text-center" ]
            [ h3 [ Spacing.mt2 ] [ text "Weather" ] ]
        |> Card.block []
            [ Block.titleH4 [] [ text weather.summary ]
            , Block.text [] [ text "Some quick example text to build on the card title and make up the bulk of the card's content." ]
            , Block.custom <|
                Button.button [ Button.primary ] [ text "Go somewhere" ]
            ]
        |> Card.view



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }



---- HTTP ----


getWeatherForecast =
    Http.get
        { url = "/weatherforecast"
        , expect = Http.expectJson GotText (JD.list weatherDecoder)
        }


weatherDecoder : Decoder Weather
weatherDecoder =
    JD.map4 Weather
        (JD.field "date" JDE.datetime)
        (JD.field "temperatureC" JD.int)
        (JD.field "temperatureF" JD.int)
        (JD.field "summary" JD.string)

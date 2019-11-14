module Main exposing (..)

import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Navbar as Navbar
import Bootstrap.Text as Text
import Bootstrap.Utilities.Spacing as Spacing
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http as Http
import Json.Decode as JD exposing (Decoder)
import Json.Decode.Extra as JDE
import Login as Login
import Time as Time exposing (Posix, Weekday(..))



---- MODEL ----


type alias Model =
    { weather : Maybe (List Weather)
    , loading : Bool
    , login : Login.Model
    , navbarState : Navbar.State
    }


type alias Weather =
    { date : Posix
    , temperatureC : Int
    , temperatureF : Int
    , summary : String
    }


init : ( Model, Cmd Msg )
init =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { weather = Nothing
      , loading = False
      , login = Login.init
      , navbarState = navbarState
      }
    , navbarCmd
    )



---- UPDATE ----


type Msg
    = NoOp
    | GetWeather
    | GetSecretWeather
    | GotWeather (Result Http.Error (List Weather))
    | LoginMsg Login.Msg
    | NavbarMsg Navbar.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        GetWeather ->
            ( { model | loading = True }, getWeatherForecast )

        GetSecretWeather ->
            case model.login.jwt of
                Just jwt ->
                    ( { model | loading = True }, getSecretWeatherForecast jwt )

                Nothing ->
                    ( model, Cmd.none )

        GotWeather result ->
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

        LoginMsg loginMsg ->
            let
                ( loginModel, loginCmd ) =
                    Login.update loginMsg model.login
            in
            ( { model | login = loginModel }
            , Cmd.map (\a -> LoginMsg a) loginCmd
            )

        NavbarMsg state ->
            ( { model | navbarState = state }, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    Grid.container []
        [ viewHeader model
        , viewBody model
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    Navbar.config NavbarMsg
        |> Navbar.dark
        |> Navbar.brand [ href "#" ]
            [ text "Shopping List" ]
        |> Navbar.customItems
            [ Navbar.formItem []
                (Login.view model.login
                    |> List.map (Html.map (\a -> LoginMsg a))
                )
            ]
        |> Navbar.view model.navbarState


viewBody : Model -> Html Msg
viewBody model =
    Grid.row []
        [ Grid.col []
            [ Grid.row [ Row.centerMd ]
                [ Grid.col []
                    [ Button.button
                        [ Button.primary, Button.attrs [ onClick GetWeather ] ]
                        [ text "Get weather" ]
                    , case model.login.jwt of
                        Just jwt ->
                            Button.button
                                [ Button.primary, Button.attrs [ onClick GetSecretWeather ] ]
                                [ text "Get weather" ]

                        Nothing ->
                            text ""
                    ]
                ]
            , Grid.row []
                [ Grid.col []
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
        ]


viewWeather : Weather -> Html msg
viewWeather weather =
    Card.config [ Card.attrs [ Spacing.my2 ] ]
        |> Card.header [ class "text-center" ]
            [ h3 [ Spacing.mt2 ] [ text (stringFromWeekday (Time.toWeekday Time.utc weather.date)) ] ]
        |> Card.block []
            [ Block.titleH4 [] [ text weather.summary ]
            , Block.text [] [ text "The temperature is estimated to be" ]
            , Block.text [] [ text (String.fromInt weather.temperatureC ++ "C" ++ String.fromChar (Char.fromCode 176)) ]
            , Block.text [] [ text (String.fromInt weather.temperatureF ++ "F" ++ String.fromChar (Char.fromCode 176)) ]
            ]
        |> Card.view


stringFromWeekday : Weekday -> String
stringFromWeekday weekday =
    case weekday of
        Mon ->
            "Monday"

        Tue ->
            "Tuesday"

        Wed ->
            "Wednesday"

        Thu ->
            "Thursday"

        Fri ->
            "Friday"

        Sat ->
            "Saturday"

        Sun ->
            "Sunday"



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
        , expect = Http.expectJson GotWeather (JD.list weatherDecoder)
        }


getSecretWeatherForecast jwt =
    let
        headers =
            [ Http.header "Authorization" ("Bearer " ++ jwt) ]
    in
    Http.request
        { method = "GET"
        , headers = headers
        , url = "/weatherforecast/secret"
        , body = Http.emptyBody
        , expect = Http.expectJson GotWeather (JD.list weatherDecoder)
        , timeout = Nothing
        , tracker = Nothing
        }


weatherDecoder : Decoder Weather
weatherDecoder =
    JD.map4 Weather
        (JD.field "date" JDE.datetime)
        (JD.field "temperatureC" JD.int)
        (JD.field "temperatureF" JD.int)
        (JD.field "summary" JD.string)

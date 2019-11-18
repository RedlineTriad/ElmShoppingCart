module Main exposing (..)

import Api.Endpoint as Endpoint
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Grid.Row as Row
import Bootstrap.Navbar as Navbar
import Bootstrap.Spinner as Spinner
import Bootstrap.Text as Text
import Bootstrap.Utilities.Spacing as Spacing
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http as Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as JDE
import Login as Login
import Time as Time exposing (..)



---- MODEL ----


type alias Model =
    { orders : Maybe (List Order)
    , loading : Bool
    , login : Login.Model
    , navbarState : Navbar.State
    }


type alias Order =
    { id : String
    , authorId : String
    , product : String
    , amount : Int
    , creationTime : Posix
    }


init : ( Model, Cmd Msg )
init =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { orders = Nothing
      , loading = False
      , login = Login.init
      , navbarState = navbarState
      }
    , navbarCmd
    )



---- UPDATE ----


type Msg
    = GetOrders Endpoint.Jwt
    | GotOrders (Result Http.Error (List Order))
    | LoginMsg Login.Msg
    | NavbarMsg Navbar.State


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
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

        GetOrders jwt ->
            ( { model | loading = True }, getOrders jwt )

        GotOrders (Ok orders) ->
            ( { model | loading = False, orders = Just orders }, Cmd.none )

        GotOrders (Err err) ->
            ( { model | loading = False }, Cmd.none )



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
                    [ case model.login.jwt of
                        Just jwt ->
                            Button.button
                                [ Button.primary, Button.attrs [ onClick (GetOrders jwt) ] ]
                                (if model.loading then
                                    [ Spinner.spinner
                                        [ Spinner.small, Spinner.attrs [ Spacing.mr1 ] ]
                                        []
                                    , text "Loading..."
                                    ]

                                 else
                                    [ text "Refresh" ]
                                )

                        Nothing ->
                            text ""
                    ]
                ]
            , Grid.row []
                [ Grid.col []
                    (case model.orders of
                        Just orders ->
                            orders |> List.map viewOrder

                        Nothing ->
                            [ text "" ]
                    )
                ]
            ]
        ]


viewOrder : Order -> Html msg
viewOrder order =
    Card.config [ Card.attrs [ Spacing.my2 ] ]
        |> Card.header [ class "text-center" ]
            [ h3 [ Spacing.mt2 ] [ text order.product ] ]
        |> Card.block []
            [ Block.text [] [ text (String.fromInt order.amount) ]
            , Block.text [] [ text <| String.fromInt <| toDay utc order.creationTime ]
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


getOrders jwt =
    Endpoint.getAuth
        Endpoint.orders
        jwt
        (Http.expectJson GotOrders (Decode.list orderDecoder))


orderDecoder : Decoder Order
orderDecoder =
    Decode.map5 Order
        (Decode.field "id" Decode.string)
        (Decode.field "authorId" Decode.string)
        (Decode.field "product" Decode.string)
        (Decode.field "amount" Decode.int)
        (Decode.field "creationTime" JDE.datetime)

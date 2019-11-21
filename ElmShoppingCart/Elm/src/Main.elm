module Main exposing (..)

import Api.Endpoint as Endpoint exposing (Jwt)
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
import Loading as Loading exposing (Loading(..))
import Login as Login
import OrderView as OrderView
import Time as Time exposing (..)



---- MODEL ----


type alias Model =
    { login : Login.Model
    , navbarState : Navbar.State
    , orderModel : OrderView.Model
    }


init : ( Model, Cmd Msg )
init =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { login = Login.init
      , navbarState = navbarState
      , orderModel = OrderView.init
      }
    , navbarCmd
    )



---- UPDATE ----


type Msg
    = LoginMsg Login.Msg
    | OrderViewMsg Jwt OrderView.Msg
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

        OrderViewMsg jwt orderMsg ->
            let
                ( orderModel, orderCmd ) =
                    OrderView.update orderMsg model.orderModel jwt
            in
            ( { model | orderModel = orderModel }
            , Cmd.map (\a -> OrderViewMsg jwt a) orderCmd
            )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    { title = "Shopping List"
    , body =
        [ viewHeader model
        , viewBody model
        ]
    }


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
    Grid.container []
        [ Grid.row []
            [ Grid.col []
                [ case Loading.toMaybe model.login.jwt of
                    Just jwt ->
                        Html.map (\a -> OrderViewMsg jwt a) (OrderView.view model.orderModel)

                    _ ->
                        text ""
                ]
            ]
        ]



---- PROGRAM ----


main : Program () Model Msg
main =
    Browser.document
        { view = view
        , init = \_ -> init
        , update = update
        , subscriptions = always Sub.none
        }



---- HTTP ----

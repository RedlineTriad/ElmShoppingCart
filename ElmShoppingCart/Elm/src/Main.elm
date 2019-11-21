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
import Loading as Loading exposing (Loading(..))
import Login as Login
import Order as Order
import Time as Time exposing (..)



---- MODEL ----


type alias Model =
    { orders : Loading Http.Error (List Order.Order)
    , login : Login.Model
    , navbarState : Navbar.State
    , orderModel : Order.CreateModel
    }


init : ( Model, Cmd Msg )
init =
    let
        ( navbarState, navbarCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { orders = NotAsked
      , login = Login.init
      , navbarState = navbarState
      , orderModel = Order.createInit
      }
    , navbarCmd
    )



---- UPDATE ----


type Msg
    = GetOrders Endpoint.Jwt
    | GotOrders (Result Http.Error (List Order.Order))
    | LoginMsg Login.Msg
    | OrderMsg Order.Msg
    | NavbarMsg Navbar.State
    | DeleteOrder Endpoint.Jwt Order.Order
    | DeletedOrder (Result Http.Error ())


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
            ( { model | orders = Loading.toLoading model.orders }, Order.getOrders jwt GotOrders )

        GotOrders (Ok orders) ->
            ( { model | orders = Success orders }, Cmd.none )

        GotOrders (Err err) ->
            ( { model | orders = Failure err }, Cmd.none )

        OrderMsg orderMsg ->
            let
                ( orderModel, orderCmd ) =
                    Order.updateCreate orderMsg model.orderModel (Loading.toMaybe model.login.jwt)
            in
            ( { model | orderModel = orderModel }
            , case ( orderMsg, Loading.toMaybe model.login.jwt ) of
                ( Order.AddedOrder _, Just jwt ) ->
                    Cmd.batch [ Cmd.map (\a -> OrderMsg a) orderCmd, Order.getOrders jwt GotOrders ]

                ( _, _ ) ->
                    Cmd.map (\a -> OrderMsg a) orderCmd
            )

        DeleteOrder jwt order ->
            ( model, Order.delete jwt order DeletedOrder )

        DeletedOrder _ ->
            case Loading.toMaybe model.login.jwt of
                Just jwt ->
                    ( model, Order.getOrders jwt GotOrders )

                Nothing ->
                    ( model, Cmd.none )



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
                [ case ( Loading.toMaybe model.login.jwt, Loading.toMaybe model.orders ) of
                    ( Just jwt, Just orders ) ->
                        Order.viewOrders (DeleteOrder jwt) orders

                    _ ->
                        text ""
                ]
            ]
        , case Loading.toMaybe model.login.jwt of
            Just jwt ->
                Grid.row []
                    [ Grid.col [] [ Html.map (\a -> OrderMsg a) (Order.viewCreate model.orderModel) ]
                    , Grid.col []
                        [ Button.button
                            [ Button.primary, Button.attrs [ onClick (GetOrders jwt) ] ]
                            (case model.orders of
                                Loading _ ->
                                    [ Spinner.spinner [ Spinner.small, Spinner.attrs [ Spacing.mr1 ] ] []
                                    , text "Loading..."
                                    ]

                                _ ->
                                    [ text "Refresh" ]
                            )
                        ]
                    ]

            Nothing ->
                text ""
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

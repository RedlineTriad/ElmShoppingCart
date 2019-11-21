module OrderView exposing (Model, Msg, init, update, view)

import Api.Endpoint exposing (Jwt)
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Spinner as Spinner
import Bootstrap.Table as Table
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (..)
import Http as Http
import Loading as Loading exposing (Loading(..))
import Order as Order exposing (CreateForm, Order)


type alias Model =
    { form : CreateForm
    , orders : Loading Http.Error (List Order)
    , adding : Bool
    }


init : Model
init =
    { form = { product = "", amount = 1 }
    , orders = NotAsked
    , adding = False
    }



-- VIEW


view : Model -> Html Msg
view model =
    Table.table
        { options = [ Table.striped, Table.hover ]
        , thead =
            Table.simpleThead
                [ Table.th [] [ text "Product" ]
                , Table.th [] [ text "Amount" ]
                , Table.th []
                    [ loadingButton
                        "Refresh"
                        "Loading..."
                        (Loading.isLoading model.orders)
                        [ Button.primary, Button.onClick GetOrders, Button.attrs [ Spacing.m1 ] ]
                    ]
                ]
        , tbody =
            Table.tbody []
                (List.append
                    (List.map (\order -> viewRow DeleteOrder order)
                        (Loading.toMaybe model.orders
                            |> Maybe.withDefault []
                        )
                    )
                    [ Table.tr []
                        [ Table.th []
                            [ Input.text
                                [ Input.value model.form.product
                                , Input.placeholder "Product"
                                , Input.onInput Product
                                , Input.attrs [ Spacing.m1 ]
                                ]
                            ]
                        , Table.th []
                            [ Input.number
                                [ Input.value (String.fromInt model.form.amount)
                                , Input.placeholder "Amount"
                                , Input.onInput Amount
                                , Input.attrs [ Spacing.m1 ]
                                ]
                            ]
                        , Table.th []
                            [ loadingButton
                                "Add"
                                "Adding"
                                model.adding
                                [ Button.primary, Button.onClick (AddOrder model), Button.attrs [ Spacing.m1 ] ]
                            ]
                        ]
                    ]
                )
        }


viewRow deleteMsg order =
    Table.tr []
        [ Table.td [] [ text order.product ]
        , Table.td [] [ text (String.fromInt order.amount) ]
        , Table.td [] [ Button.button [ Button.danger, Button.onClick (deleteMsg order) ] [ text "Delete" ] ]
        ]


loadingButton : String -> String -> Bool -> List (Button.Option msg) -> Html msg
loadingButton defaultText loadingText loading buttonOptions =
    Button.button (Button.disabled loading :: buttonOptions)
        (case loading of
            True ->
                [ Spinner.spinner [ Spinner.small, Spinner.attrs [ Spacing.mr1 ] ] []
                , text defaultText
                ]

            False ->
                [ text defaultText ]
        )



-- UPDATE


type Msg
    = Product String
    | Amount String
    | AddOrder Model
    | AddedOrder (Result Http.Error ())
    | DeleteOrder Order
    | DeletedOrder (Result Http.Error ())
    | GetOrders
    | GotOrders (Result Http.Error (List Order))


update : Msg -> Model -> Jwt -> ( Model, Cmd Msg )
update msg model jwt =
    case msg of
        Product product ->
            updateCreateForm (\form -> { form | product = product }) model

        Amount amountString ->
            case String.toInt amountString of
                Just amount ->
                    updateCreateForm (\form -> { form | amount = amount }) model

                Nothing ->
                    ( model, Cmd.none )

        AddOrder order ->
            ( { model | adding = True }, Order.addOrder jwt order.form AddedOrder )

        AddedOrder _ ->
            ( { model | adding = False }, Order.getOrders jwt GotOrders )

        DeleteOrder order ->
            ( model, Order.delete jwt order DeletedOrder )

        DeletedOrder _ ->
            ( model, Order.getOrders jwt GotOrders )

        GetOrders ->
            ( { model | orders = Loading.toLoading model.orders }, Order.getOrders jwt GotOrders )

        GotOrders result ->
            ( { model | orders = Loading.fromResult result }, Cmd.none )


updateCreateForm : (CreateForm -> CreateForm) -> Model -> ( Model, Cmd Msg )
updateCreateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )

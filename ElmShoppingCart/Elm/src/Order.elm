module Order exposing (CreateModel, Msg(..), Order, addOrder, createInit, delete, getOrders, orderDecoder, updateCreate, viewCreate, viewOrders)

import Api.Endpoint as Endpoint exposing (Jwt)
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Spinner as Spinner
import Bootstrap.Table as Table
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (..)
import Html.Attributes exposing (..)
import Http as Http
import Json.Decode as Decode exposing (Decoder)
import Json.Decode.Extra as JDE
import Json.Encode as Encode
import Time exposing (Posix, toDay, utc)



-- TYPES


type alias Order =
    { id : String
    , authorId : String
    , product : String
    , amount : Int
    , creationTime : Posix
    }


type alias CreateModel =
    { form : CreateForm
    , sending : Bool
    }


createInit : CreateModel
createInit =
    { form = { product = "", amount = 1 }
    , sending = False
    }


type alias CreateForm =
    { product : String
    , amount : Int
    }



-- VIEW


viewOrders : (Order -> msg) -> List Order -> Html msg
viewOrders deleteMsg orders =
    Table.table
        { options = [ Table.striped, Table.hover ]
        , thead =
            Table.simpleThead
                [ Table.th [] [ text "Product" ]
                , Table.th [] [ text "Amount" ]
                ]
        , tbody =
            Table.tbody []
                (List.map
                    (\order ->
                        Table.tr []
                            [ Table.td [] [ text order.product ]
                            , Table.td [] [ text (String.fromInt order.amount) ]
                            , Table.td [] [ Button.button [ Button.danger, Button.onClick (deleteMsg order) ] [ text "Delete" ] ]
                            ]
                    )
                    orders
                )
        }


viewCreate : CreateModel -> Html Msg
viewCreate model =
    Form.formInline []
        [ Input.text
            [ Input.value model.form.product
            , Input.placeholder "Product"
            , Input.onInput Product
            , Input.attrs [ Spacing.m1 ]
            , Input.disabled model.sending
            ]
        , Input.number
            [ Input.value (String.fromInt model.form.amount)
            , Input.placeholder "Amount"
            , Input.onInput Amount
            , Input.attrs [ Spacing.m1 ]
            , Input.disabled model.sending
            ]
        , Button.button
            [ Button.primary
            , Button.onClick (AddOrder model)
            , Button.attrs [ Spacing.m1 ]
            , Button.disabled model.sending
            ]
            (case model.sending of
                True ->
                    [ Spinner.spinner
                        [ Spinner.small, Spinner.attrs [ Spacing.mr1 ] ]
                        []
                    , text "Adding..."
                    ]

                False ->
                    [ text "Add" ]
            )
        ]



-- UPDATE


type Msg
    = Product String
    | Amount String
    | AddOrder CreateModel
    | AddedOrder (Result Http.Error ())


updateCreate : Msg -> CreateModel -> Maybe Jwt -> ( CreateModel, Cmd Msg )
updateCreate msg model jwt =
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
            case jwt of
                Just justJwt ->
                    ( { model | sending = True }, addOrder justJwt order.form AddedOrder )

                Nothing ->
                    ( model, Cmd.none )

        AddedOrder _ ->
            ( { model | sending = False }, Cmd.none )


updateCreateForm : (CreateForm -> CreateForm) -> CreateModel -> ( CreateModel, Cmd Msg )
updateCreateForm transform model =
    ( { model | form = transform model.form }, Cmd.none )



-- HTTP


getOrders : Jwt -> (Result Http.Error (List Order) -> a) -> Cmd a
getOrders jwt expect =
    Endpoint.getAuth
        Endpoint.orders
        jwt
        (Http.expectJson expect (Decode.list orderDecoder))


addOrder : Jwt -> CreateForm -> (Result Http.Error () -> a) -> Cmd a
addOrder jwt form expect =
    Endpoint.postAuth
        { url = Endpoint.orders
        , body = Http.jsonBody (createFormEncoder form)
        , expect = Http.expectWhatever expect
        , jwt = jwt
        }


delete : Jwt -> Order -> (Result Http.Error () -> msg) -> Cmd msg
delete jwt order expect =
    Endpoint.deleteAuth
        { url = Endpoint.order order.id
        , expect = Http.expectWhatever expect
        , jwt = jwt
        }



-- CODERS


orderDecoder : Decoder Order
orderDecoder =
    Decode.map5 Order
        (Decode.field "id" Decode.string)
        (Decode.field "authorId" Decode.string)
        (Decode.field "product" Decode.string)
        (Decode.field "amount" Decode.int)
        (Decode.field "creationTime" JDE.datetime)


createFormEncoder : CreateForm -> Encode.Value
createFormEncoder form =
    Encode.object
        [ ( "product", Encode.string form.product )
        , ( "amount", Encode.int form.amount )
        ]

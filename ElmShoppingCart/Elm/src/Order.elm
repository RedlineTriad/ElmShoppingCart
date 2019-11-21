module Order exposing (CreateForm, Order, addOrder, delete, getOrders, orderDecoder)

import Api.Endpoint as Endpoint exposing (Jwt)
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


type alias CreateForm =
    { product : String
    , amount : Int
    }



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

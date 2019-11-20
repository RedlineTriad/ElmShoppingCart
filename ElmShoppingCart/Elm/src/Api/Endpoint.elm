module Api.Endpoint exposing (Endpoint, Jwt, RequestConfig, decodeJwt, encodeJwt, getAuth, login, order, orders, post, postAuth, register, request, requestAuth, unwrap)

import Http
import Url.Builder as Builder exposing (QueryParameter)


request : RequestConfig a -> Cmd a
request config =
    Http.request
        { body = config.body
        , expect = config.expect
        , headers = config.headers
        , method = config.method
        , timeout = config.timeout
        , url = unwrap config.url
        , tracker = config.tracker
        }


requestAuth : RequestConfig a -> Jwt -> Cmd a
requestAuth config jwt =
    let
        header =
            Http.header "Authorization" ("Bearer " ++ decodeJwt jwt)
    in
    request
        { body = config.body
        , expect = config.expect
        , headers = header :: config.headers
        , method = config.method
        , timeout = config.timeout
        , url = config.url
        , tracker = config.tracker
        }


postAuth :
    { url : Endpoint
    , body : Http.Body
    , expect : Http.Expect a
    , jwt : Jwt
    }
    -> Cmd a
postAuth config =
    requestAuth
        { body = config.body
        , expect = config.expect
        , headers = []
        , method = "POST"
        , timeout = Nothing
        , url = config.url
        , tracker = Nothing
        }
        config.jwt


post :
    { url : Endpoint
    , body : Http.Body
    , expect : Http.Expect a
    }
    -> Cmd a
post config =
    Http.post
        { url = unwrap config.url
        , body = config.body
        , expect = config.expect
        }


getAuth : Endpoint -> Jwt -> Http.Expect a -> Cmd a
getAuth endpoint jwt expect =
    requestAuth
        { body = Http.emptyBody
        , expect = expect
        , headers = []
        , method = "GET"
        , timeout = Nothing
        , url = endpoint
        , tracker = Nothing
        }
        jwt


type alias RequestConfig a =
    { body : Http.Body
    , expect : Http.Expect a
    , headers : List Http.Header
    , method : String
    , timeout : Maybe Float
    , url : Endpoint
    , tracker : Maybe String
    }


type Endpoint
    = Endpoint String


unwrap : Endpoint -> String
unwrap (Endpoint str) =
    str


type Jwt
    = Jwt String


decodeJwt : Jwt -> String
decodeJwt (Jwt jwt) =
    jwt


encodeJwt : String -> Jwt
encodeJwt string =
    Jwt string


url : List String -> List QueryParameter -> Endpoint
url paths queryParams =
    Builder.relative
        ("api" :: paths)
        queryParams
        |> Endpoint



-- ENDPOINTS


login : Endpoint
login =
    url [ "account", "login" ] []


register : Endpoint
register =
    url [ "account", "register" ] []



-- ORDER


orders : Endpoint
orders =
    url [ "order" ] []


order : String -> Endpoint
order id =
    url [ "order", id ] []

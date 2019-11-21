module Login exposing (Model, Msg, init, update, view)

import Api.Endpoint as Endpoint
import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (..)
import Http as Http
import Json.Encode as Encode
import Loading as Loading exposing (Loading(..))


type alias Model =
    { email : String
    , password : String
    , jwt : Loading Http.Error Endpoint.Jwt
    }


init : Model
init =
    { email = ""
    , password = ""
    , jwt = NotAsked
    }


type Msg
    = Email String
    | Password String
    | GetJWT
    | GotJWT (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Email string ->
            ( { model | email = string }, Cmd.none )

        Password string ->
            ( { model | password = string }, Cmd.none )

        GetJWT ->
            ( { model | jwt = Loading.toLoading model.jwt }, getJWT model.email model.password )

        GotJWT (Ok jwt) ->
            ( { model | jwt = Success (Endpoint.encodeJwt jwt) }, Cmd.none )

        GotJWT (Err err) ->
            ( { model | jwt = Failure err }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    case model.jwt of
        Success _ ->
            [ p [] [ text "Logged in" ] ]

        Loading _ ->
            [ p [] [ text "Logging in" ] ]

        _ ->
            [ Input.email [ Input.value model.email, Input.placeholder "email", Input.onInput Email, Input.attrs [ Spacing.m1 ] ]
            , Input.password [ Input.value model.password, Input.placeholder "password", Input.onInput Password, Input.attrs [ Spacing.m1 ] ]
            , Button.button [ Button.primary, Button.attrs [ Spacing.m1 ], Button.onClick GetJWT ]
                [ text "Log-in"
                ]
            ]


getJWT : String -> String -> Cmd Msg
getJWT email password =
    Endpoint.post
        { url = Endpoint.login
        , body = Http.jsonBody (loginEncoder email password)
        , expect = Http.expectString GotJWT
        }


loginEncoder : String -> String -> Encode.Value
loginEncoder email password =
    Encode.object
        [ ( "Email", Encode.string email )
        , ( "Password", Encode.string password )
        ]

module Login exposing (Model, Msg, init, update, view)

import Bootstrap.Button as Button
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.InputGroup as InputGroup
import Bootstrap.Text as Text
import Bootstrap.Utilities.Spacing as Spacing
import Html exposing (..)
import Http as Http
import Json.Encode as Encode


type alias Model =
    { email : String
    , password : String
    , jwt : Maybe String
    , loggingIn : Bool
    }


init : Model
init =
    { email = ""
    , password = ""
    , jwt = Nothing
    , loggingIn = False
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
            ( { model | loggingIn = True }, getJWT model.email model.password )

        GotJWT result ->
            case result of
                Ok jwt ->
                    ( { model | loggingIn = False, jwt = Just jwt }, Cmd.none )

                Err err ->
                    ( { model | loggingIn = False }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    case ( model.jwt, model.loggingIn ) of
        ( Just string, _ ) ->
            [ p [] [ text "Logged in" ] ]

        ( Nothing, False ) ->
            [ Input.email [ Input.value model.email, Input.placeholder "email", Input.onInput Email, Input.attrs [ Spacing.m1 ] ]
            , Input.password [ Input.value model.password, Input.placeholder "password", Input.onInput Password, Input.attrs [ Spacing.m1 ] ]
            , Button.button [ Button.primary, Button.attrs [ Spacing.m1 ], Button.onClick GetJWT ]
                [ text "Log-in"
                ]
            ]

        ( Nothing, True ) ->
            [ p [] [ text "Logging in" ] ]


getJWT email password =
    Http.post
        { url = "/api/account/login"
        , body = Http.jsonBody (loginEncoder email password)
        , expect = Http.expectString GotJWT
        }


loginEncoder : String -> String -> Encode.Value
loginEncoder email password =
    Encode.object
        [ ( "Email", Encode.string email )
        , ( "Password", Encode.string password )
        ]

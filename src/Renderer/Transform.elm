module Renderer.Transform exposing
    ( transformUnion, transformUnion2
    , transformValue
    , transformType
    )

{-| Transform `Docs` tree into `CodeGen` tree.


# Transformation


## Union

@docs transformUnion, transformUnion2


## Value

@docs transformValue


## Type

@docs transformType

-}

import Elm.CodeGen as Gen
import Elm.Docs as Docs
import Elm.Syntax.Node as Node
import Elm.Syntax.Range exposing (emptyRange)
import Elm.Syntax.Signature as Sig
import Elm.Syntax.Type as SyntaxType
import Elm.Type as Type


{-| Construct tree from an `Union`.
-}
transformUnion : Docs.Union -> Gen.Declaration
transformUnion union =
    Gen.customTypeDecl
        Nothing
        union.name
        union.args
        (transformTag union.name union.tags)


{-| Construct tree from an `Union`.
-}
transformUnion2 : Docs.Union -> SyntaxType.Type
transformUnion2 union =
    { documentation = Nothing
    , name = docNode union.name
    , generics = union.args |> List.map docNode
    , constructors = transformCtor2 union.name union.tags
    }


{-| -}
transformCtor2 :
    String
    -> List ( String, List Type.Type )
    -> List (Node.Node SyntaxType.ValueConstructor)
transformCtor2 tname tags =
    case tags of
        [] ->
            List.singleton <|
                docNode
                    { name = docNode tname
                    , arguments = []
                    }

        variants ->
            List.map
                (\( tag, tparams ) ->
                    docNode <|
                        { name = docNode tag
                        , arguments = List.map (docNode << transformType) tparams
                        }
                )
                variants


{-| -}
transformTag : String -> List ( String, List Type.Type ) -> List ( String, List Gen.TypeAnnotation )
transformTag tname tags =
    case tags of
        [] ->
            [ ( tname, [] )
            ]

        variants ->
            variants
                |> List.map
                    (\( tag, tparams ) ->
                        ( tag
                        , List.map transformType tparams
                        )
                    )


transformValue : Docs.Value -> Sig.Signature
transformValue value =
    Gen.signature
        value.name
        (transformType value.tipe)


{-| Construct tree from a `Type`.
-}
transformType : Type.Type -> Gen.TypeAnnotation
transformType tipe =
    case tipe of
        Type.Var tparam ->
            Gen.typeVar tparam

        Type.Lambda t1 t2 ->
            Gen.funAnn
                (transformType t1)
                (transformType t2)

        Type.Tuple tparams ->
            Gen.tupleAnn
                (tparams |> List.map transformType)

        Type.Type tname tparams ->
            Gen.typed tname
                (List.map transformType tparams)

        Type.Record fields maybeExt ->
            let
                annotatedFields =
                    fields |> (List.map <| Tuple.mapSecond transformType)
            in
            case maybeExt of
                Just ext ->
                    Gen.extRecordAnn ext annotatedFields

                Nothing ->
                    Gen.recordAnn annotatedFields


docNode : a -> Node.Node a
docNode =
    Node.Node emptyRange

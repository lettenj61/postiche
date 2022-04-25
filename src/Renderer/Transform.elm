module Renderer.Transform exposing
    ( transformUnion
    , transformType
    )

{-| Transform `Docs` tree into `CodeGen` tree.


# Transformation


## Union

@docs transformUnion


## Type

@docs transformType

-}

import Elm.CodeGen as Gen
import Elm.Docs as Docs
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
